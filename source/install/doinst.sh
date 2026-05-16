#!/bin/sh

mkdir -p /boot/config/plugins/lucky
mkdir -p /boot/config/plugins/lucky/luckyconf
mkdir -p /usr/local/sbin
AUTOSTART="array"

if [ ! -f /boot/config/plugins/lucky/lucky.cfg ]; then
  cp /usr/local/emhttp/plugins/lucky/defaults/lucky.cfg /boot/config/plugins/lucky/lucky.cfg
fi

if [ -f /boot/config/plugins/lucky/lucky.cfg ]; then
  . /boot/config/plugins/lucky/lucky.cfg
fi

case "$AUTOSTART" in
  yes|array) AUTOSTART="array" ;;
  boot) AUTOSTART="boot" ;;
  *) AUTOSTART="no" ;;
esac

chmod 0755 /usr/local/lucky/lucky
ln -sf /usr/local/lucky/lucky /usr/local/sbin/lucky
chmod 0755 /etc/rc.d/rc.lucky
chmod 0755 /usr/local/emhttp/plugins/lucky/event/started
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-autostart
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-status
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-upstream-update
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule
rm -f /usr/local/emhttp/plugins/lucky/lucky-api.php
rm -f /usr/local/emhttp/plugins/lucky/scripts/lucky-control-job
rm -f /usr/local/emhttp/plugins/lucky/scripts/lucky-plugin-update
/usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule apply >/dev/null 2>&1 || true

if [ -x /boot/config/plugins/lucky/upstream/lucky ]; then
  cp /boot/config/plugins/lucky/upstream/lucky /usr/local/lucky/lucky
  chmod 0755 /usr/local/lucky/lucky
fi

if [ -s /boot/config/plugins/lucky/upstream/VERSION ]; then
  cp /boot/config/plugins/lucky/upstream/VERSION /usr/local/emhttp/plugins/lucky/VERSION
fi

if [ "$AUTOSTART" = "boot" ] && [ -x /usr/local/emhttp/plugins/lucky/scripts/lucky-autostart ]; then
  /usr/local/emhttp/plugins/lucky/scripts/lucky-autostart boot >/dev/null 2>&1 &
fi
