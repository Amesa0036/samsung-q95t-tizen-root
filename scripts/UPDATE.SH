#!/bin/sh
# tvroot verification collector v2 - no exploit needed.
# Triggered by the tvroot agent (polls USB every 5s) or by boot.sh at boot.
# Waits for this boot's debloat to finish, then dumps the verification
# bundle to \TVCHECK on the stick.
for U in /opt/media/USBDrive*; do [ -d "$U" ] && break; done
OUT=$U/TVCHECK
mkdir -p $OUT 2>/dev/null || exit 0
echo QUEUED > $OUT/STATUS.TXT
sync
(
setsid sh -c '
for U in /opt/media/USBDrive*; do [ -d "$U" ] && break; done
OUT=$U/TVCHECK
D=/opt/usr/share/tvroot
i=0
while [ $i -lt 60 ]; do
  u=$(cut -d. -f1 /proc/uptime)
  [ "$u" -ge 90 ] && break
  sleep 5
  i=$((i+1))
done
{ date; cat /proc/uptime; } > $OUT/DATE.TXT 2>&1
cp $D/debloat.log $OUT/DEBLOAT.LOG 2>/dev/null
cp $D/apply.log $OUT/APPLY.LOG 2>/dev/null
cp $D/update.log $OUT/UPDATE.LOG 2>/dev/null
sha256sum /etc/profile.d/bash_prompt_custom.sh > $OUT/LIVE.SHA 2>&1
mount > $OUT/MOUNT.TXT 2>&1
mount | grep hosts > $OUT/HOSTS.TXT 2>&1
for s in acr contents-recognition-service vision-data-recognition-service vdsystem-update-manager org.tizen.remotepc background-update com.samsung.tv.airplay-service hbbtv-service ambient-ua-agent; do
  echo "$s: $(systemctl is-active $s 2>/dev/null)"
done > $OUT/UNITS.TXT 2>&1
ls -lR $D > $OUT/TVROOT.LS 2>&1
free -m > $OUT/MEM.TXT 2>&1
sync
echo DONE > $OUT/DONE.TXT
sync
'
) &
exit 0
