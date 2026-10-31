#!/bin/sh
# tvroot rollback helper - lives on the TV at /opt/usr/share/tvroot/backup/rollback.sh
# Restores the original rootfs block(s) from the byte-exact backup made at patch time.
# hook-location.sh is written by the installer and sets DEV/BLKSTART/NBLOCKS/BACKUP/LIVE_SHA.
. /opt/usr/share/tvroot/backup/hook-location.sh
F=/etc/profile.d/bash_prompt_custom.sh
dd if=$BACKUP of=$DEV bs=512 seek=$BLKSTART count=$NBLOCKS conv=notrunc 2>/dev/null || { echo "FAIL write"; exit 1; }
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
sha256sum $F
echo "expected: $LIVE_SHA"
