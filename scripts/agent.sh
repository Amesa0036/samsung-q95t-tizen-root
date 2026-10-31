#!/bin/sh
# tvroot USB update agent v1 - one-shot body; debloat's supervisor loop
# re-runs it every 5s. Runs UPDATE.SH from any mounted USB stick, once per
# boot per file content. Scope: physical USB only (no 0777 command queue).
for F in /opt/media/USBDrive*/UPDATE.SH; do
  [ -f "$F" ] || continue
  S=$(md5sum "$F" 2>/dev/null | cut -d' ' -f1)
  [ -n "$S" ] || continue
  [ "$S" = "$(cat /run/tvroot-upd.last 2>/dev/null)" ] && continue
  echo "$S" > /run/tvroot-upd.last 2>/dev/null
  echo "=== $(date) running $F (md5 $S)" >> /opt/usr/share/tvroot/update.log
  /bin/sh -c "$(cat "$F")" >> /opt/usr/share/tvroot/update.log 2>&1
  echo "=== done rc=$?" >> /opt/usr/share/tvroot/update.log
done
exit 0
