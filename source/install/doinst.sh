#!/bin/sh

mkdir -p /boot/config/plugins/lucky
mkdir -p /boot/config/plugins/lucky/luckyconf
mkdir -p /usr/local/sbin

if [ ! -f /boot/config/plugins/lucky/lucky.cfg ]; then
  cp /usr/local/emhttp/plugins/lucky/defaults/lucky.cfg /boot/config/plugins/lucky/lucky.cfg
fi

chmod 0755 /usr/local/lucky/lucky
ln -sf /usr/local/lucky/lucky /usr/local/sbin/lucky
chmod 0755 /etc/rc.d/rc.lucky
chmod 0755 /usr/local/emhttp/plugins/lucky/event/started
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-status
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-plugin-update
chmod 0755 /usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule
/usr/local/emhttp/plugins/lucky/scripts/lucky-update-schedule apply >/dev/null 2>&1 || true
