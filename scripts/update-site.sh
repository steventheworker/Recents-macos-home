#!/bin/sh
# Website edits for the release pipeline. Called by scripts/publish-release.sh
# with: VERSION OLD_VERSION DOWNLOAD_URL PUB_DATE_HUMAN BULLETS_FILE NOTES_URL
#       PRODUCT_NAME RELEASE_ZIP_NAME APPCAST
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

printf '%s\n' "$VERSION" > "$ROOT/currentversion.txt"

python3 - "$ROOT" "$VERSION" "$OLD_VERSION" "$DOWNLOAD_URL" "$PUB_DATE_HUMAN" "${BULLETS_FILE:-}" "$PRODUCT_NAME" "$RELEASE_ZIP_NAME" "$NOTES_URL" <<'PY'
import html, pathlib, re, sys

root, version, old, download_url, date, bullets_file, product, zip_name, notes_url = sys.argv[1:10]
root = pathlib.Path(root)
zip = zip_name.replace("{VERSION}", version)

def update_file(rel):
    path = root / rel
    if not path.exists():
        return
    text = path.read_text()
    text = text.replace("0.0.0", version)
    if old:
        text = text.replace(f"v{old}", f"v{version}")
        text = text.replace(old, version)
    text = re.sub(
        r"https://github\.com/[^/\s\"]+/[^/\s\"]+/releases/download/v[0-9.]+/\S+",
        download_url,
        text,
    )
    path.write_text(text)

for rel in ("index.html", "README.md"):
    update_file(rel)

def insert_release(rel, indent):
    path = root / rel
    if not path.exists() or not bullets_file or not pathlib.Path(bullets_file).stat().st_size:
        return
    bullets = [l.strip() for l in pathlib.Path(bullets_file).read_text().splitlines() if l.strip()]
    if not bullets:
        return
    block = "\n".join([
        f'{indent}<section class="release" data-version="{html.escape(version)}">',
        f'{indent}  <h3><a href="{html.escape(notes_url)}">v{html.escape(version)}</a></h3>',
        f'{indent}  <p class="release-date">{html.escape(date)} · <a href="{html.escape(download_url)}">Download {html.escape(zip)}</a></p>',
        f'{indent}  <ul>',
        *[f'{indent}    <li>{html.escape(b)}</li>' for b in bullets],
        f'{indent}  </ul>',
        f'{indent}</section>',
    ])
    text = path.read_text()
    pattern = re.compile(
        r'(?ms)^[ \t]*<section class="release" data-version="'
        + re.escape(version) + r'">.*?</section>[ \t]*\n?'
    )
    if pattern.search(text):
        text = pattern.sub(block + "\n", text, count=1)
    elif "<!-- release-list -->" in text:
        text = text.replace("<!-- release-list -->", "<!-- release-list -->\n" + block, 1)
    else:
        return
    path.write_text(text)

insert_release("index.html", "      ")
insert_release("changelog-sparkle/index.html", "    ")
PY
