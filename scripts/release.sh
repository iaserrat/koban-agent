#!/bin/bash
#
# release.sh - cut a signed, notarized Koban Agent release and publish it to the Sparkle feed.
#
# Koban auto-updates with Sparkle (https://sparkle-project.org). Updates are full builds only,
# never deltas. Every release is hosted as an asset on a single rolling GitHub release (tag
# "updates"); the cumulative appcast.xml lives there too, which is exactly the URL baked into the
# app as SUFeedURL. The EdDSA private key that signs each build lives in the macOS keychain and is
# never committed; the matching public key is SUPublicEDKey in Config/Info.plist.
#
# Usage:
#   ./scripts/release.sh <version>          # e.g. ./scripts/release.sh 1.1.0
#
# Prerequisites (one-time):
#   - Sparkle signing key in the keychain: run Sparkle's `generate_keys` once. The public key it
#     prints (`generate_keys -p`) must equal SUPublicEDKey in Config/Info.plist.
#   - Notarization credentials stored as a keychain profile named "notarytool":
#       xcrun notarytool store-credentials notarytool --apple-id <id> --team-id <team> --password <app-specific-password>
#   - A Developer ID Application signing identity in the keychain.
#   - GitHub CLI authenticated with write access: `gh auth status`.
#   - KOBAN_DEVELOPMENT_TEAM set (env or Config/Signing.local.xcconfig).

set -euo pipefail

# --- Configuration (no bare literals below this block) ------------------------------------------
APP_NAME="Koban Agent"
SCHEME="Koban Agent"
PROJECT="Koban Agent.xcodeproj"
GITHUB_REPO="iaserrat/koban-agent"
# Single rolling release that accumulates every signed DMG plus the appcast. Its download path is
# the app's SUFeedURL, so do not rename it without re-releasing every installed client.
UPDATES_TAG="updates"
DOWNLOAD_URL_PREFIX="https://github.com/${GITHUB_REPO}/releases/download/${UPDATES_TAG}/"
APPCAST_NAME="appcast.xml"
NOTARY_PROFILE="notarytool"
EXPORT_METHOD="developer-id"
# Single source of truth for the version, committed on every release so it is tracked in git.
VERSION_XCCONFIG="Config/Version.xcconfig"

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"
BUILD_DIR="${REPO_ROOT}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
DMG_STAGE_DIR="${BUILD_DIR}/dmg"
# Holds every released DMG plus the appcast so generate_appcast can rebuild the cumulative feed.
FEED_DIR="${BUILD_DIR}/feed"

step() { printf '\n\033[1;36m==>\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

# --- Parse and validate arguments ---------------------------------------------------------------
[ $# -eq 1 ] || fail "usage: ./scripts/release.sh <version>  (e.g. 1.1.0)"
VERSION="$1"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "version must be MAJOR.MINOR.PATCH (e.g. 1.1.0)"

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
# Monotonic CFBundleVersion Sparkle compares to decide "is this newer". The version reads straight
# off the build number (1.2.3 -> 123), so minor and patch must each stay below 10, otherwise the
# encoding stops increasing monotonically (1.0.10 would collide with 1.1.0 at 110).
{ [ "$MINOR" -lt 10 ] && [ "$PATCH" -lt 10 ]; } || fail "minor and patch must each be < 10 (got ${VERSION}); the build-number encoding requires it"
BUILD_NUMBER=$((MAJOR * 100 + MINOR * 10 + PATCH))
DMG_NAME="${APP_NAME// /-}-${VERSION}.dmg"
DMG_PATH="${FEED_DIR}/${DMG_NAME}"

# --- Resolve the development team ----------------------------------------------------------------
TEAM_ID="${KOBAN_DEVELOPMENT_TEAM:-}"
if [ -z "$TEAM_ID" ] && [ -f "Config/Signing.local.xcconfig" ]; then
    TEAM_ID="$(sed -n 's/^KOBAN_DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*//p' Config/Signing.local.xcconfig | tr -d '[:space:]')"
fi
[ -n "$TEAM_ID" ] || fail "set KOBAN_DEVELOPMENT_TEAM (env or Config/Signing.local.xcconfig)"

# --- Locate Sparkle's tools (shipped inside the resolved SPM artifact) ---------------------------
command -v gh >/dev/null 2>&1 || fail "GitHub CLI 'gh' is required (brew install gh)"
gh auth status >/dev/null 2>&1 || fail "gh is not authenticated (run: gh auth login)"

xcodebuild -project "$PROJECT" -scheme "$SCHEME" -resolvePackageDependencies >/dev/null
SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData -type d -path '*artifacts/sparkle/Sparkle/bin' 2>/dev/null | head -1)"
[ -n "$SPARKLE_BIN" ] || fail "Sparkle tools not found; build the app once so SPM resolves Sparkle."
GENERATE_APPCAST="${SPARKLE_BIN}/generate_appcast"

step "Releasing ${APP_NAME} ${VERSION} (build ${BUILD_NUMBER}), team ${TEAM_ID}"
rm -rf "$BUILD_DIR"
mkdir -p "$FEED_DIR"

# --- 1. Stamp the version into the tracked xcconfig ---------------------------------------------
# Config/Version.xcconfig is the single source of truth: the app generates its Info.plist from build
# settings (GENERATE_INFOPLIST_FILE) and those settings resolve from this file. We rewrite it here
# and commit it after a successful publish, so the released version lives in git.
step "Stamping ${VERSION_XCCONFIG} to ${VERSION} (build ${BUILD_NUMBER})"
cat > "$VERSION_XCCONFIG" <<XCCONFIG
// Single source of truth for the app version. scripts/release.sh rewrites both values on every
// release and commits this file, so the released version is tracked in git. GENERATE_INFOPLIST_FILE
// turns these into CFBundleShortVersionString and CFBundleVersion. Build number is derived from the
// version as major*100 + minor*10 + patch (so 1.2.3 -> 123); keep minor and patch below 10.
MARKETING_VERSION = ${VERSION}
CURRENT_PROJECT_VERSION = ${BUILD_NUMBER}
XCCONFIG

# --- 2. Archive ---------------------------------------------------------------------------------
step "Archiving ${VERSION} (build ${BUILD_NUMBER}) (Release, Developer ID)"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    >/dev/null

# --- 3. Export a Developer ID signed app --------------------------------------------------------
step "Exporting Developer ID app"
EXPORT_OPTIONS="${BUILD_DIR}/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>${EXPORT_METHOD}</string>
	<key>teamID</key>
	<string>${TEAM_ID}</string>
	<key>signingStyle</key>
	<string>automatic</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    >/dev/null

APP_PATH="${EXPORT_DIR}/${APP_NAME}.app"
[ -d "$APP_PATH" ] || fail "export did not produce ${APP_PATH}"

# Guard against a botched bump: the binary's version and build number must both match what we are
# about to publish, or Sparkle would mis-order the update for everyone already installed.
INFO_PLIST="${APP_PATH}/Contents/Info.plist"
EMBEDDED_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
[ "$EMBEDDED_VERSION" = "$VERSION" ] || fail "exported app is ${EMBEDDED_VERSION}, expected ${VERSION}"
EMBEDDED_BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")"
[ "$EMBEDDED_BUILD" = "$BUILD_NUMBER" ] || fail "exported build is ${EMBEDDED_BUILD}, expected ${BUILD_NUMBER}"

# --- 4. Build the DMG ---------------------------------------------------------------------------
step "Building ${DMG_NAME}"
mkdir -p "$DMG_STAGE_DIR"
cp -R "$APP_PATH" "$DMG_STAGE_DIR/"
ln -s /Applications "$DMG_STAGE_DIR/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGE_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

# --- 5. Notarize and staple ---------------------------------------------------------------------
# Staple before signing the appcast: the EdDSA signature must cover the exact bytes users download.
step "Notarizing with Apple (profile: ${NOTARY_PROFILE})"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"

# --- 6. Rebuild the cumulative appcast ----------------------------------------------------------
# Pull the previously released DMGs and appcast so generate_appcast emits a feed covering every
# version (and preserves existing pubDates/notes), then signs the new build with the keychain key.
step "Generating ${APPCAST_NAME}"
gh release download "$UPDATES_TAG" --repo "$GITHUB_REPO" --dir "$FEED_DIR" --pattern '*.dmg' 2>/dev/null || true
gh release download "$UPDATES_TAG" --repo "$GITHUB_REPO" --dir "$FEED_DIR" --pattern "$APPCAST_NAME" 2>/dev/null || true
"$GENERATE_APPCAST" "$FEED_DIR" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --maximum-deltas 0 \
    -o "${FEED_DIR}/${APPCAST_NAME}"

# --- 7. Publish to the rolling updates release --------------------------------------------------
step "Publishing to GitHub release '${UPDATES_TAG}'"
if ! gh release view "$UPDATES_TAG" --repo "$GITHUB_REPO" >/dev/null 2>&1; then
    gh release create "$UPDATES_TAG" \
        --repo "$GITHUB_REPO" \
        --title "${APP_NAME} update feed" \
        --notes "Sparkle appcast and signed builds for ${APP_NAME}. Managed by scripts/release.sh; do not delete." \
        --latest=false
fi
gh release upload "$UPDATES_TAG" "$DMG_PATH" "${FEED_DIR}/${APPCAST_NAME}" --repo "$GITHUB_REPO" --clobber

# --- 8. Record the version in git ---------------------------------------------------------------
# Commit only the bumped version file (leaving any unrelated WIP untouched) and tag the release, so
# git is the record of what shipped. Pushing stays manual: the script never writes to the remote.
TAG="v${VERSION}"
step "Recording ${VERSION} in git"
if git diff --quiet -- "$VERSION_XCCONFIG"; then
    printf '  %s already at %s; nothing to commit.\n' "$VERSION_XCCONFIG" "$VERSION"
else
    git commit --quiet -m "Release ${VERSION}" -- "$VERSION_XCCONFIG"
    printf '  Committed %s bump.\n' "$VERSION_XCCONFIG"
fi
if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    printf '  Tag %s already exists; left as is.\n' "$TAG"
else
    git tag -a "$TAG" -m "${APP_NAME} ${VERSION}"
    printf '  Tagged %s.\n' "$TAG"
fi

step "Done. ${APP_NAME} ${VERSION} is live on the Sparkle feed."
printf '  DMG:     %s%s\n' "$DOWNLOAD_URL_PREFIX" "$DMG_NAME"
printf '  Appcast: %s%s\n' "$DOWNLOAD_URL_PREFIX" "$APPCAST_NAME"
printf '\nPush the release commit and tag: git push && git push origin %s\n' "$TAG"
