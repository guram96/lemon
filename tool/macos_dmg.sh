#!/usr/bin/env bash
# Build the release macOS client, bundle the headless server inside the app,
# and pack it into a drag-to-Applications disk image.
# After the server files are copied in, the app is ad-hoc re-signed
# (`codesign --sign -`) so those files are inside the signature.
# Does not use a Developer ID, keychain, or notarization.
#
# `dart compile exe` cannot build this server: the SDK rejects it for packages
# with build hooks, and sqlite3 uses a hook to ship its own libsqlite3.
# `dart build cli` writes:
#   bundle/bin/rs_server
#   bundle/lib/libsqlite3.dylib
# The library's install name is @rpath/lib/libsqlite3.dylib, and the executable
# has an rpath of @executable_path/.. . With rs_server at Contents/MacOS/rs_server
# the library must be Contents/lib/libsqlite3.dylib. A copy beside the binary
# is not loaded. Do not commit either file.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: tool/macos_dmg.sh only runs on macOS (Darwin)." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter was not found on PATH." >&2
  exit 1
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "error: dart was not found on PATH." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLIENT_DIR="${REPO_ROOT}/apps/client"
SERVER_DIR="${REPO_ROOT}/apps/server"
APP_PATH="${CLIENT_DIR}/build/macos/Build/Products/Release/retro_steam.app"
SERVER_OUT="${SERVER_DIR}/build/cli"
SERVER_BIN="${SERVER_OUT}/bundle/bin/rs_server"
SERVER_LIB="${SERVER_OUT}/bundle/lib/libsqlite3.dylib"
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

echo "Building bundled server..."
(
  cd "${SERVER_DIR}"
  dart build cli -o "${SERVER_OUT}"
)

if [[ ! -f "${SERVER_BIN}" || ! -f "${SERVER_LIB}" ]]; then
  echo "error: server bundle incomplete (expected ${SERVER_BIN} and ${SERVER_LIB})" >&2
  exit 1
fi

# Flutter replaces the .app, so the server is copied in after that build.
mkdir -p "${APP_PATH}/Contents/MacOS" "${APP_PATH}/Contents/lib"
cp -p "${SERVER_BIN}" "${APP_PATH}/Contents/MacOS/rs_server"
cp -p "${SERVER_LIB}" "${APP_PATH}/Contents/lib/libsqlite3.dylib"
chmod +x "${APP_PATH}/Contents/MacOS/rs_server"

if [[ ! -x "${APP_PATH}/Contents/MacOS/rs_server" ]]; then
  echo "error: failed to install rs_server into the app" >&2
  exit 1
fi
if [[ ! -f "${APP_PATH}/Contents/lib/libsqlite3.dylib" ]]; then
  echo "error: failed to install libsqlite3.dylib into the app" >&2
  exit 1
fi

# Flutter ad-hoc-signs the bundle before these files exist. Re-sign so macOS
# does not treat the added server binary and library as a damaged app.
# `--deep` is deprecated; if this codesign rejects it, sign inside-out.
echo "Ad-hoc signing the app..."
if ! codesign --force --deep --sign - "${APP_PATH}"; then
  codesign --force --sign - "${APP_PATH}/Contents/lib/libsqlite3.dylib"
  codesign --force --sign - "${APP_PATH}/Contents/MacOS/rs_server"
  codesign --force --sign - "${APP_PATH}"
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
