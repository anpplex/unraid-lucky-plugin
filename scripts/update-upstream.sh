#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_URL="${LUCKY_RELEASE_API:-https://api.github.com/repos/gdy666/lucky/releases/latest}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

release_json="$TMP_DIR/release.json"
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" "$API_URL" -o "$release_json"
else
  curl -fsSL "$API_URL" -o "$release_json"
fi

release_info="$(
  python3 - "$release_json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    release = json.load(handle)

tag = release.get("tag_name", "")
version = tag[1:] if tag.startswith("v") else tag
asset_name = f"lucky_{version}_Linux_x86_64.tar.gz"
asset_url = ""

for asset in release.get("assets", []):
    if asset.get("name") == asset_name:
        asset_url = asset.get("browser_download_url", "")
        break

if not version or not asset_url:
    raise SystemExit(f"Unable to find x86_64 Lucky asset for release tag {tag!r}")

print(version)
print(asset_name)
print(asset_url)
PY
)"

VERSION="$(printf '%s\n' "$release_info" | sed -n '1p')"
ASSET_NAME="$(printf '%s\n' "$release_info" | sed -n '2p')"
ASSET_URL="$(printf '%s\n' "$release_info" | sed -n '3p')"
MIRROR_URL="https://release.66666.host/v${VERSION}/${VERSION}_lucky/${ASSET_NAME}"
ARCHIVE="$TMP_DIR/$ASSET_NAME"
CURRENT_VERSION="$(sed -n -e 's/^VERSION=//p' -e '/^[0-9]/{p;q;}' "$ROOT_DIR/VERSION" 2>/dev/null | head -n 1 || true)"
CURRENT_PLUGIN_VERSION="$(sed -n -e 's/^PLUGIN_VERSION=//p' -e '/^[0-9]/{p;q;}' "$ROOT_DIR/PLUGIN_VERSION" 2>/dev/null | head -n 1 || true)"

downloaded=no
for url in "$MIRROR_URL" "$ASSET_URL"; do
  echo "Downloading $url"
  if curl -fsSL --connect-timeout 20 --max-time 180 -o "$ARCHIVE" "$url"; then
    downloaded=yes
    break
  fi
done

if [[ "$downloaded" != "yes" ]]; then
  echo "Failed to download $ASSET_NAME" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  SHA256="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
else
  SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
fi

printf '%s\n' "$VERSION" > "$ROOT_DIR/VERSION"
if [[ "$VERSION" != "$CURRENT_VERSION" || -z "$CURRENT_PLUGIN_VERSION" ]]; then
  printf '%s\n' "$VERSION" > "$ROOT_DIR/PLUGIN_VERSION"
else
  printf '%s\n' "$CURRENT_PLUGIN_VERSION" > "$ROOT_DIR/PLUGIN_VERSION"
fi
printf '%s\n' "$SHA256" > "$ROOT_DIR/UPSTREAM_SHA256"

mkdir -p "$ROOT_DIR/dist/upstream"
cp "$ARCHIVE" "$ROOT_DIR/dist/upstream/$ASSET_NAME"

echo "Lucky upstream version: $VERSION"
echo "Lucky upstream sha256:  $SHA256"
