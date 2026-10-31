# Rooting the Samsung Q95T (Tizen 5.5, NikeM) - confirmed on QE75Q95TATXXC

First documented root of the Samsung Q95T using the Q90T-family NikeM chain. This repo holds the write-up, the operational pitfalls we hit, and the original maintenance scripts we built on top of the upstream exploit. **The exploit itself is upstream** - see credits below.

- **Device:** Samsung QE75Q95TATXXC (2020 Q95T, 75")
- **Firmware:** T-NKMDEUC-2743.0
- **Platform:** NikeM, Tizen 5.5, kernel Linux 4.1.10 (Samsung), ARMv7l

> Single-device evidence on one exact firmware. Do not extrapolate to other sizes, regions or firmware versions. Rooting your TV can brick it (a wrong USB image hung our unit more than once - mains recovery only). No warranty, no support.

## TL;DR

The Q90T NikeM root chain works on the Q95T essentially unchanged. The vendor hook file `/etc/profile.d/bash_prompt_custom.sh` is byte-identical to the Q90T's (776 bytes, sha256 in [hashes.txt](hashes.txt)), the A/B rootfs layout matches, and the documented 512-byte raw block swap achieves boot persistence. On top of that we verified live: 13 systemd masks + hosts sinkhole + package disables (9/9 target units inactive across 7 logged boots, with and without the USB stick), plus a hot-plug `UPDATE.SH` maintenance channel that runs any script as root with no exploit and no reboot.

## Credits

- **[Luminger/samsung-tv-usb-root](https://github.com/Luminger/samsung-tv-usb-root)** - the original 2019 exFAT exploit (Muse.M). The whole chain stands on this.
- **[gtalusan/samsung-q90t-tizen-root](https://github.com/gtalusan/samsung-q90t-tizen-root)** - the NikeM derivation for the Q90T, including the persistence method and methodology docs we followed.
- **cfloinc** - related Q90T work (persistent-hook scripts our debloat derives from).

This repo adds only: Q95T confirmation, the pitfalls below, and the maintenance scripts in [scripts/](scripts/).

## What worked unchanged from the Q90T docs

- The NikeM chain addresses and trigger constants.
- The 512-byte raw block swap of the vendor profile script; VDFS has no per-file content digests, so the edit is read-transparent.
- The UEP bypass (`sh -c "$(cat ...)"` content-as-argument form) - required and sufficient, exactly as documented in `docs/methodology/06-uep.md` upstream.

## Pitfalls found on the Q95T (6 image iterations - the short version)

1. vfat `shortname=mixed` case-sensitivity: the payload path must match the on-disk name byte-for-byte.
2. `nohup` is absent - use `setsid`.
3. A kernel-stage beacon dies after ~60 s unless detached (`setsid`).
4. `sync` against a worn stick can hang the worker - background syncs + socket-first liveness markers.
5. UEP blocks `bash -n /path/to/script` - use `bash -nc "<content>"`.
6. busybox `grep` needs `[[:space:]]`, not `\t`.
7. `ncat` without `-k` dies after one connection.
8. **Hot-plug beats cold boot** (3/3 vs coin flip).
9. A boot-time one-shot `UPDATE.SH` check misses late USB mounts - fixed with a 5-second polling watcher agent; the filename must be exactly `UPDATE.SH`.

Full details in [docs/pitfalls.md](docs/pitfalls.md).

## Repo layout

- [hashes.txt](hashes.txt) - vendor-file and patched-file hashes so you can verify your unit's compatibility before touching anything.
- [scripts/boot.sh](scripts/boot.sh) - boot entry run as root from the patched profile.d script (UEP-safe content-exec, boot-time UPDATE.SH channel).
- [scripts/debloat.sh](scripts/debloat.sh) - masks, stops, hosts sinkhole, package disables, agent supervisor start, delayed census (derived from the upstream persistent-hook script, UEP-down section removed).
- [scripts/agent.sh](scripts/agent.sh) - watcher: runs `/opt/media/USBDrive*/UPDATE.SH` once per content hash per boot. Physical-USB scope only, no command queue.
- [scripts/hosts.block](scripts/hosts.block) - the ad/ACR domain list bind-mounted over `/etc/hosts`.
- [scripts/UPDATE.SH](scripts/UPDATE.SH) - verification collector: dumps the whole state (debloat log, live hash, mounts, unit census, memory) to `\TVCHECK` on the stick.
- [scripts/rollback.sh](scripts/rollback.sh) - on-TV helper restoring the original rootfs block from the byte-exact backup.
- [scripts/UPDATE-ROLLBACK.SH](scripts/UPDATE-ROLLBACK.SH) - full rollback through the UPDATE channel: rename to `UPDATE.SH`, hot-plug, reboot. No exploit stick needed to revert.

## Security notes (read before replicating)

- Any USB with an `UPDATE.SH` in its root runs as root on the TV. Physical access is game over anyway, but don't leave unknown sticks plugged in.
- Never install a Samsung firmware update after patching (auto-update paths are masked; don't run a manual USB update either): new firmware loses the patch and may close the exploit.
- Never disable UEP via the kernel levers: the verifier-entry patch boot-loops a Q90T per the upstream docs, and the status-global write is unstable. The content-as-argument form covers all needs.
- The patched vendor file and the USB exploit image are **not** distributed here (they derive from Samsung firmware). Verify your unit against [hashes.txt](hashes.txt) and follow the upstream repos for the exploit itself.

## Reverting

The rollback kit lives on the TV at `/opt/usr/share/tvroot/backup/` (original rootfs blocks, pristine vendor file, rollback.sh). Easiest path: put [scripts/UPDATE-ROLLBACK.SH](scripts/UPDATE-ROLLBACK.SH) on a stick renamed to `UPDATE.SH`, hot-plug, wait for `\TVCHECK\ROLLBACK.TXT`, reboot. Masks and the sinkhole are per-boot and disappear on their own.
