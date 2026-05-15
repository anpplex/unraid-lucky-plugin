#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="${1:-${PLUGIN_BASE_URL:-}}"
VERSION="$(sed -n -e 's/^VERSION=//p' -e '/^[0-9]/{p;q;}' "$ROOT_DIR/VERSION" | head -n 1)"
PLUGIN_VERSION="$(sed -n -e 's/^PLUGIN_VERSION=//p' -e '/^[0-9]/{p;q;}' "$ROOT_DIR/PLUGIN_VERSION" | head -n 1)"
UPSTREAM_SHA256="$(sed -n -e 's/^SHA256=//p' -e '/^[0-9a-fA-F]/{p;q;}' "$ROOT_DIR/UPSTREAM_SHA256" | head -n 1)"
PKG_NAME="lucky-${PLUGIN_VERSION}-x86_64-1.txz"
DIST_DIR="$ROOT_DIR/dist"
PKG_DIR="$DIST_DIR/packages"
BUILD_DIR="$DIST_DIR/build/lucky-package"
PKG_PATH="$PKG_DIR/$PKG_NAME"
PLG_TEMPLATE="$ROOT_DIR/templates/lucky.plg.in"
PLG_PATH="$DIST_DIR/lucky.plg"
STANDALONE_PLG_PATH="$DIST_DIR/lucky-x86_64.plg"
UPSTREAM_DIR="$DIST_DIR/upstream"
UPSTREAM_ARCHIVE="$UPSTREAM_DIR/lucky_${VERSION}_Linux_x86_64.tar.gz"
ICON_URL="${LUCKY_ICON_URL:-https://cdn.jsdelivr.net/gh/IceWhaleTech/CasaOS-AppStore@main/Apps/Lucky/icon.png}"
UPSTREAM_URLS=(
  "https://release.66666.host/v${VERSION}/${VERSION}_lucky/lucky_${VERSION}_Linux_x86_64.tar.gz"
  "https://github.com/gdy666/lucky/releases/download/v${VERSION}/lucky_${VERSION}_Linux_x86_64.tar.gz"
)

if [[ -z "$BASE_URL" ]]; then
  echo "usage: $0 https://raw.githubusercontent.com/<owner>/<repo>/main" >&2
  exit 2
fi

if [[ -z "$VERSION" || -z "$PLUGIN_VERSION" || -z "$UPSTREAM_SHA256" ]]; then
  echo "VERSION, PLUGIN_VERSION, and UPSTREAM_SHA256 must be set" >&2
  exit 2
fi

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

download_lucky_binary() {
  mkdir -p "$UPSTREAM_DIR"
  if [[ -f "$UPSTREAM_ARCHIVE" ]] && [[ "$(sha256_file "$UPSTREAM_ARCHIVE")" == "$UPSTREAM_SHA256" ]]; then
    return
  fi

  rm -f "$UPSTREAM_ARCHIVE"
  for url in "${UPSTREAM_URLS[@]}"; do
    echo "Downloading $url"
    if curl -L --fail --connect-timeout 20 --max-time 180 -o "$UPSTREAM_ARCHIVE" "$url"; then
      break
    fi
  done

  if [[ ! -f "$UPSTREAM_ARCHIVE" ]]; then
    echo "failed to download Lucky x86_64 binary archive" >&2
    exit 1
  fi

  actual_sha="$(sha256_file "$UPSTREAM_ARCHIVE")"
  if [[ "$actual_sha" != "$UPSTREAM_SHA256" ]]; then
    echo "sha256 mismatch for $UPSTREAM_ARCHIVE" >&2
    echo "expected: $UPSTREAM_SHA256" >&2
    echo "actual:   $actual_sha" >&2
    exit 1
  fi
}

download_lucky_binary

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$PKG_DIR"
rm -f "$PKG_DIR"/lucky-*-x86_64-1.txz
cp -R "$ROOT_DIR/source/." "$BUILD_DIR/"
if [[ -f "$BUILD_DIR/usr/local/emhttp/plugins/lucky/lucky.png.b64" ]]; then
  base64 -d < "$BUILD_DIR/usr/local/emhttp/plugins/lucky/lucky.png.b64" > "$BUILD_DIR/usr/local/emhttp/plugins/lucky/lucky.png"
  rm -f "$BUILD_DIR/usr/local/emhttp/plugins/lucky/lucky.png.b64"
else
  if ! curl -L --fail --connect-timeout 20 --max-time 60 -o "$BUILD_DIR/usr/local/emhttp/plugins/lucky/lucky.png" "$ICON_URL"; then
    echo "failed to download Lucky plugin icon" >&2
    exit 1
  fi
fi
mkdir -p "$BUILD_DIR/usr/local/lucky"
tar -xzf "$UPSTREAM_ARCHIVE" -C "$BUILD_DIR/usr/local/lucky" lucky LICENSE scripts
chmod 0755 "$BUILD_DIR/usr/local/lucky/lucky"

mkdir -p "$BUILD_DIR/install"
cat > "$BUILD_DIR/install/slack-desc" <<'DESC'
lucky: lucky
lucky:
lucky: Lucky Linux x86_64 binary plugin for Unraid.
lucky:
lucky: This package installs an Unraid Settings page, rc script,
lucky: autostart event hook, and the upstream Lucky executable.
lucky:
lucky:
lucky:
lucky:
lucky:
DESC

chmod 0755 "$BUILD_DIR/etc/rc.d/rc.lucky"
chmod 0755 "$BUILD_DIR/usr/local/emhttp/plugins/lucky/event/started"
chmod 0755 "$BUILD_DIR/usr/local/emhttp/plugins/lucky/scripts/lucky-status"
chmod 0755 "$BUILD_DIR/usr/local/emhttp/plugins/lucky/scripts/lucky-plugin-update"
chmod 0755 "$BUILD_DIR/usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule"
chmod 0755 "$BUILD_DIR/install/doinst.sh"

tar -C "$BUILD_DIR" --owner=0 --group=0 -cJf "$PKG_PATH" .

if command -v md5sum >/dev/null 2>&1; then
  MD5="$(md5sum "$PKG_PATH" | awk '{print $1}')"
elif command -v md5 >/dev/null 2>&1; then
  MD5="$(md5 -q "$PKG_PATH")"
else
  echo "md5sum or md5 is required" >&2
  exit 1
fi

base64_encode_file() {
  if base64 --help 2>&1 | grep -q -- '-w'; then
    base64 -w 76 "$1"
  elif base64 -b 76 -i "$1" >/dev/null 2>&1; then
    base64 -b 76 -i "$1"
  elif base64 "$1" >/dev/null 2>&1; then
    base64 "$1" | fold -w 76
  else
    base64 -i "$1" | fold -w 76
  fi
}

emit_base64_file_blocks() {
  local pkg="$1"
  local chunk_lines=5000
  local chunk=0

  base64_encode_file "$pkg" | awk -v chunk_lines="$chunk_lines" '
    (NR - 1) % chunk_lines == 0 {
      if (NR > 1) {
        print "LUCKY_PACKAGE_BASE64"
        print "    ]]></INLINE>"
        print "  </FILE>"
      }
      chunk++
      print "  <FILE Run=\"/bin/bash\">"
      print "    <INLINE><![CDATA["
      print "cat >> /boot/config/plugins/lucky/lucky-package.b64 <<'\''LUCKY_PACKAGE_BASE64'\''"
    }
    { print }
    END {
      if (NR > 0) {
        print "LUCKY_PACKAGE_BASE64"
        print "    ]]></INLINE>"
        print "  </FILE>"
      }
    }
  '
}

PLUGIN_URL="${BASE_URL%/}/dist/lucky.plg"
PKG_URL="${BASE_URL%/}/dist/packages/$PKG_NAME"
sed \
  -e "s|@VERSION@|$VERSION|g" \
  -e "s|@PLUGIN_VERSION@|$PLUGIN_VERSION|g" \
  -e "s|@PLUGIN_URL@|$PLUGIN_URL|g" \
  -e "s|@PACKAGE_URL@|$PKG_URL|g" \
  -e "s|@PACKAGE_MD5@|$MD5|g" \
  "$PLG_TEMPLATE" > "$PLG_PATH"

{
  cat <<EOF
<?xml version="1.0" standalone="yes"?>
<!DOCTYPE PLUGIN [
<!ENTITY name "lucky">
<!ENTITY author "Apex">
<!ENTITY version "$PLUGIN_VERSION">
<!ENTITY pluginURL "$PLUGIN_URL">
<!ENTITY launch "Settings/Lucky">
]>
<PLUGIN name="&name;"
        author="&author;"
        version="&version;"
        pluginURL="&pluginURL;"
        launch="&launch;">

  <CHANGES>
## $PLUGIN_VERSION

- Install Lucky ${VERSION} Linux x86_64 binary directly.
- Add Lucky runtime controls, update controls, and a compact plugin summary.
- Add Chinese/English plugin UI language switching, defaulting to Chinese.
- Add persistent runtime configuration under /boot/config/plugins/lucky.
- Add boot and array-start Lucky autostart modes.
- Refine Chinese autostart option labels.
- Add pluginURL metadata so Unraid can check plugin updates.
  </CHANGES>

  <FILE Run="/bin/bash">
    <INLINE><![CDATA[
set -e
mkdir -p /boot/config/plugins/lucky
: > /boot/config/plugins/lucky/lucky-package.b64
    ]]></INLINE>
  </FILE>
EOF
  emit_base64_file_blocks "$PKG_PATH"
  cat <<EOF
  <FILE Run="/bin/bash">
    <INLINE><![CDATA[
set -e
PKG="/boot/config/plugins/lucky/$PKG_NAME"
B64="/boot/config/plugins/lucky/lucky-package.b64"
base64 -d < "\$B64" > "\$PKG"
rm -f "\$B64"
echo "$MD5  \$PKG" | md5sum -c -
upgradepkg --install-new "\$PKG"
if [ ! -f /boot/config/plugins/lucky/lucky.cfg ]; then
  cp /usr/local/emhttp/plugins/lucky/defaults/lucky.cfg /boot/config/plugins/lucky/lucky.cfg
fi
mkdir -p /boot/config/plugins/lucky/luckyconf /usr/local/sbin
ln -sf /usr/local/lucky/lucky /usr/local/sbin/lucky
chmod 0755 /usr/local/lucky/lucky
chmod 0755 /etc/rc.d/rc.lucky
chmod 0755 /usr/local/emhttp/plugins/lucky/event/started
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-status
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-plugin-update
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule
/usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule apply >/dev/null 2>&1 || true
    ]]></INLINE>
  </FILE>

  <FILE Run="/bin/bash" Method="remove">
    <INLINE><![CDATA[
/etc/rc.d/rc.lucky stop >/dev/null 2>&1 || true
removepkg lucky >/dev/null 2>&1 || true
rm -rf /usr/local/emhttp/plugins/lucky
rm -rf /usr/local/lucky
rm -f /usr/local/sbin/lucky
rm -f /etc/rc.d/rc.lucky
    ]]></INLINE>
  </FILE>
</PLUGIN>
EOF
} > "$STANDALONE_PLG_PATH"

echo "Built $PKG_PATH"
echo "Built $PLG_PATH"
echo "Built $STANDALONE_PLG_PATH"
