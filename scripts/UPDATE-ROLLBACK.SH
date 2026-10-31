#!/bin/sh
# tvroot ROLLBACK via UPDATE channel. Rename to UPDATE.SH on the stick root
# ONLY when a full rollback is wanted. Restores the original vendor file
# blocks (removes the persistent hook), then REBOOT the TV.
for U in /opt/media/USBDrive*; do [ -d "$U" ] && break; done
OUT=$U/TVCHECK
mkdir -p $OUT 2>/dev/null
{
  echo "=== rollback $(date)"
  /bin/sh /opt/usr/share/tvroot/backup/rollback.sh
  echo "=== rollback rc=$?"
} > $OUT/ROLLBACK.TXT 2>&1
sync
exit 0
