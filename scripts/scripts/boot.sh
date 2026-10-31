#!/bin/sh
# tvroot boot entry (v8c: + UPDATE.SH channel) — runs as root from the patched profile.d script.
# UEP-safe: debloat.sh is passed by CONTENT, never exec'd.
LOG=/opt/usr/share/tvroot/debloat.log
DIR=/opt/usr/share/tvroot
[ -e /run/.tvroot-debloat ] && exit 0
: > /run/.tvroot-debloat 2>/dev/null
mkdir -p "$DIR" 2>/dev/null
# self-update channel: a plain USB stick carrying UPDATE.SH runs as root at
# boot (no exploit needed once the hook is installed). UEP-safe: content-exec.
U=/opt/media/USBDriveA1/UPDATE.SH
[ -f "$U" ] || U=/opt/media/USBDriveA2/UPDATE.SH
if [ -f "$U" ]; then
  echo "=== tvroot UPDATE.SH found, running" >> "$LOG"
  /bin/sh -c "$(cat "$U")" >> "$LOG" 2>&1
  echo "=== tvroot UPDATE.SH done" >> "$LOG"
fi
{
  up=$(read up rest < /proc/uptime 2>/dev/null; echo "$up")
  echo "=== tvroot boot entry uptime=${up}s uid=$(id -u 2>/dev/null) ctx=$(cat /proc/self/attr/current 2>/dev/null)"
  if [ -f "$DIR/debloat.sh" ]; then
    /bin/sh -c "$(cat "$DIR/debloat.sh")"
  else
    echo "=== debloat.sh missing"
  fi
  echo "=== tvroot boot entry done"
} >> "$LOG" 2>&1
:
