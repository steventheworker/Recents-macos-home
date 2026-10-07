#!/bin/sh
# Product-specific configuration for the *-home release pipeline.
# Consumed by scripts/deploy.sh and scripts/publish-release.sh (canonical).
# Placeholders are filled by scripts/scaffold-home-repo.sh.

# --- product identity ---------------------------------------------------------
PRODUCT_NAME="Recents"
# GitHub repo that hosts releases/tags (usually the -home repo itself).
RELEASE_REPOSITORY="steventheworker/Recents-macos-home"
SITE_URL="https://recents-macos.netlify.app"

# --- source app ---------------------------------------------------------------
SOURCE_ROOT="${RECENTS_SOURCE_ROOT:-$HOME/proj/obj-c/Recents}"
# Xcode project used by scripts/deploy.sh.
XCODE_KIND="project"                 # "project" | "workspace"
XCODE_PROJECT="Recents.xcodeproj"
XCODE_WORKSPACE=""
XCODE_SCHEME="Recents"
XCODE_CONFIGURATION="Release"
RELEASE_ZIP_NAME="Recents-macos-{VERSION}.zip"
SOURCE_METADATA_FILE=""
SOURCE_METADATA_COMMIT_MSG="chore(release): prepare Recents v{VERSION}"

# --- Sparkle appcast ----------------------------------------------------------
APPCAST="appcast.xml"
MIN_OS="14.0"
NOTES_URL_BASE="$SITE_URL"
CURRENT_VERSION_CMD="tr -d '[:space:]' < currentversion.txt"
SIGN_UPDATE_CANDIDATES=""
RELEASE_NOTES_CONTEXT="Recents is a macOS app. Re-arrange or delete Recent Items in App Exposé."
RELEASE_NOTES_EXCLUDE=""
RELEASE_TITLE="Recents {VERSION}"
SITE_COMMIT_MSG="publish Recents v{VERSION}"

# Files the canonical publisher stages (the appcast is added automatically).
SITE_FILES="index.html README.md currentversion.txt changelog-sparkle/index.html"
