#!/usr/bin/env bash
# Build the release macOS client and pack it into a drag-to-Applications disk image.
# Does not codesign, notarize, or read Apple ID, certificate, or keychain secrets.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: tool/macos_dmg.sh only runs on macOS (Darwin)." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter was not found on PATH." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLIENT_DIR="${REPO_ROOT}/apps/client"
APP_PATH="${CLIENT_DIR}/build/macos/Build/Products/Release/retro_steam.app"
DIST_DIR="${REPO_ROOT}/dist"
DMG_PATH="${DIST_DIR}/RetroSteam-macos.dmg"

STAGING=""
cleanup() {
  if [[ -n "${STAGING}" && -d "${STAGING}" ]]; then
    rm -rf "${STAGING}"
  fi
}
trap cleanup EXIT

echo "Building release macOS client..."
(
  cd "${CLIENT_DIR}"
  flutter build macos --release
)

if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: release app not found at ${APP_PATH}" >&2
  exit 1
fi

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/retro-steam-dmg.XXXXXX")"
# Copy the bundle so the image is self-contained. ditto keeps the .app layout intact.
ditto "${APP_PATH}" "${STAGING}/retro_steam.app"
ln -s /Applications "${STAGING}/Applications"

mkdir -p "${DIST_DIR}"
rm -f "${DMG_PATH}"

hdiutil create \
  -volname "Retro Steam" \
  -srcfolder "${STAGING}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "${DMG_PATH}"
