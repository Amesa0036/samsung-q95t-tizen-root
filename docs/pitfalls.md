# Q95T pitfalls - 6 image iterations distilled

Device: QE75Q95TATXXC, T-NKMDEUC-2743.0, Tizen 5.5 NikeM. These cost us six USB image builds; maybe they save you a few.

## 1. vfat `shortname=mixed` case-sensitivity

The TV's vfat mount preserves case in a way that makes the trigger path case-sensitive. The payload path baked into the image must match the on-disk filename byte-for-byte, including case. A file that shows as `STAGE1.SH` on Windows and `stage1.sh` in the image silently never triggers.

## 2. `nohup` is absent

This rootfs ships no `nohup`. Any stage that must survive its parent needs `setsid` instead.

## 3. Kernel-stage beacon dies after ~60 s

A callback/beacon spawned from the kernel-triggered stage gets reaped with the session after about a minute. Detach with `setsid` (see 2) or it looks like the exploit "fired and died".

## 4. `sync` can hang the worker on worn sticks

Cheap/worn USB flash + dirsync + flush interplay can stall a foreground `sync` long enough to look like a hang (or to miss a timing window). Fix: background the syncs and use socket-first progress markers, so the host side sees liveness even when a sync stalls.

## 5. UEP blocks `bash -n /path/to/script`

Syntax-checking a script *by path* opens the file as a script and trips Samsung's UEP signature gate, same as executing it. Use the content form: `bash -nc "$(cat /path/to/script)"`. Same rule as the runtime bypass - never let UEP see an unsigned *file*.

## 6. busybox `grep` has no `\t`

Patterns with `\t` silently match nothing. Use `[[:space:]]`.

## 7. `ncat` without `-k` dies after one connection

For the host-side listener, `ncat -l 4444` accepts exactly one connection and exits. Use `ncat -l -k 4444` for any reconnecting shell or multi-stage payload.

## 8. Hot-plug beats cold boot

Inserting the exploit stick with the TV **fully booted** worked 3/3 for us. Cold-boot insertion was a coin flip - the USB mount timing races the exploit trigger window. Boot the TV, wait 2-3 minutes, then plug the stick.

## 9. Boot-time one-shot UPDATE.SH misses late USB mounts

A single "is there an UPDATE.SH?" check at boot runs before the stick finishes mounting on most boots, so it structurally always fails (retries only catch it by luck). Fix: a tiny watcher agent (`scripts/agent.sh`) started by the debloat supervisor that polls `/opt/media/USBDrive*/` every 5 seconds and runs `UPDATE.SH` exactly once per file content hash per boot (md5 stamp in `/run`). This turns the maintenance channel into a true hot-plug channel: plug the stick any time, script runs in ~10 seconds, no exploit, no reboot. Caveat: the filename must be exactly `UPDATE.SH`, case included.
