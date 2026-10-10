#!/bin/sh
# Website edits for the release pipeline. Called by scripts/publish-release.sh
# with: VERSION OLD_VERSION DOWNLOAD_URL PUB_DATE_HUMAN BULLETS_FILE NOTES_URL
#       PRODUCT_NAME RELEASE_ZIP_NAME APPCAST
#
# Contract:
#   - currentversion.txt is set to VERSION;
#   - the "Latest" pointer in index.html/README.md points at VERSION;
#   - a release section is inserted (or replaced, when re-run) for VERSION;
#   - historical release sections and their download URLs are never modified.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

printf '%s\n' "$VERSION" > "$ROOT/currentversion.txt"

python3 - "$ROOT" "$VERSION" "$OLD_VERSION" "$DOWNLOAD_URL" "$PUB_DATE_HUMAN" "${BULLETS_FILE:-}" "$PRODUCT_NAME" "$RELEASE_ZIP_NAME" "$NOTES_URL" <<'PY'
import html, pathlib, re, sys

root, version, old, download_url, date, bullets_file, product, zip_name, notes_url = sys.argv[1:10]
root = pathlib.Path(root)
zip = zip_name.replace("{VERSION}", version)

# Anchor for "the current release" on the landing page: everything above the
# changelog list is regenerated; everything below it is history and is kept.
LIST_MARKER = "<!-- release-list -->"
DOWNLOAD_URL_RE = re.compile(
    r"https://github\.com/[^/\s\"]+/[^/\s\"]+/releases/download/v[0-9.]+/[^\"\s<]+"
)


def read_bullets():
    if not bullets_file:
        return []
    path = pathlib.Path(bullets_file)
    if not path.exists() or not path.stat().st_size:
        return []
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]


def update_pointer(rel):
    """Update only the current-version pointer, never historical entries."""
    path = root / rel
    if not path.exists():
        return
    text = path.read_text()
    text = text.replace("@@VERSION@@", version)
    # index.html: "Latest: v1.2.3"   README.md: "Latest release: **X v1.2.3**"
    text = re.sub(
        r"(Latest:\s*)(?:v)?\d+\.\d+\.\d+",
        lambda m: f"{m.group(1)}v{version}",
        text,
        count=1,
    )
    text = re.sub(
        r"(Latest release:[^\n]*?)(?:v)?\d+\.\d+\.\d+",
        lambda m: f"{m.group(1)}v{version}",
        text,
        count=1,
    )
    # A versioned download link in the hero (above the changelog) tracks the
    # current release; the historical sections below keep their own URLs.
    head, marker, tail = text.partition(LIST_MARKER)
    if marker and rel == "index.html":
        head = DOWNLOAD_URL_RE.sub(download_url, head)
        text = head + marker + tail
    path.write_text(text)


def release_block(indent, bullets):
    lines = [
        f'{indent}<section class="release" data-version="{html.escape(version)}">',
        f'{indent}  <h3><a href="{html.escape(notes_url)}">v{html.escape(version)}</a></h3>',
        f'{indent}  <p class="release-date">{html.escape(date)} · '
        f'<a href="{html.escape(download_url)}">Download {html.escape(zip)}</a></p>',
    ]
    if bullets:
        lines.append(f"{indent}  <ul>")
        lines.extend(f"{indent}    <li>{html.escape(bullet)}</li>" for bullet in bullets)
        lines.append(f"{indent}  </ul>")
    lines.append(f"{indent}</section>")
    return "\n".join(lines)


def insert_release(rel, indent):
    path = root / rel
    if not path.exists():
        return
    bullets = read_bullets()
    if not bullets:
        return
    text = path.read_text()
    block = release_block(indent, bullets)
    pattern = re.compile(
        r'(?ms)^[ \t]*<section class="release" data-version="'
        + re.escape(version)
        + r'">.*?</section>[ \t]*\n?'
    )
    if pattern.search(text):
        # Re-running the same version replaces its entry instead of duplicating.
        text = pattern.sub(block + "\n", text, count=1)
    elif LIST_MARKER in text:
        # New version: prepend above the previous releases (newest first).
        text = text.replace(LIST_MARKER, LIST_MARKER + "\n" + block, 1)
    else:
        return
    path.write_text(text)


update_pointer("index.html")
update_pointer("README.md")
insert_release("index.html", "      ")
insert_release("changelog-sparkle/index.html", "    ")
PY
