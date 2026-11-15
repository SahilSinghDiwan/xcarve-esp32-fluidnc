# X-Carve controller audit → ESP32 replacement

Audited 2026-11-15 from the Pi SD card (read-only; card never mounted or written).
Backup image `rootfs.img` was deleted after the audit; small useful files are in `../legacy-pi/` (read-only, sparse, all allocated blocks, `e2fsck -fn` clean).

## What the Pi was doing

| Thing | Finding | Evidence |
|---|---|---|
| Machine | Inventables **X-Carve** | hostname `xcarve`; Easel driver installed |
| OS | Raspbian Stretch, 2019-04-08 image | `/boot/issue.txt` |
| Sender | **CNCjs 1.9.20** (confirmed) on Node 10, run by pm2 at boot, port 8000, port 80 redirected to 8000 by iptables | `~/.pm2/dump.pm2`, `/etc/iptables/rules.v4`, `pm2-pi.service` |
| Link to Arduino | USB serial `/dev/ttyACM0` (GRBL protocol) | CNCjs log, 213 mentions |
| Also installed | Easel driver 0.3.10 (installed but not started at boot: crontab is empty), ChiliPeppr serial-port-json-server (init.d script) | `~/easel-driver`, `/etc/init.d/serial-port-json-server` |
| Macro | "Go to top left" = `G0 X0 Y320` | `~/.cncrc` |
| Custom pendants (not started at boot) | GPIO4 button + GPIO17 LED: hold, coolant, `$X`, `$SLP`, `$H`. Power-sense on GPIO4: `!` on power loss, `~` on return. USB keyboard jog | `~/cncjs-pendant-*` |
| Camera | Pi camera time-lapse every 5 min | `~/time_lapse_camera/capture.py` |
| Usage | Regular use from May 2019 to Jun 2022. Booted again 2025-11-09: **Arduino not found on ttyACM0** (unplugged or dead) | `~/.pm2/logs/cncjs-out.log` |

**Not on the card:** the GRBL settings (`$$`). They live in the Uno's EEPROM.

## Verdict: a plain ESP32 is enough

- Firmware: **FluidNC** on an ESP32-WROOM-32 DevKit. It replaces both boards:
  - motion control (the Uno's job)
  - built-in Wi-Fi web UI with jog, macros, SD-card job running, and a Telnet/USB GRBL port (the Pi's job)
- **ESP32-S3** also works, but FluidNC's S3 support only arrived in the v4 pre-releases. It's newer and less tested. There's no reason to pay for it here.
- The old pendant functions map to FluidNC's native `control:` pins: feed hold, cycle start, and `macro0..3` (e.g. `$H`). Power-sense → `feed_hold_pin`.
- **What you lose:**
  - Easel (needs its own driver on a computer)
  - the Pi camera time-lapse (would need a separate ESP32-CAM if wanted)
  - the USB keyboard pendant (the web UI jogs instead)
- CNCjs can still be used from a laptop: it connects to FluidNC over USB or Telnet.

## Draft config

`../fluidnc/config.yaml`: ESP32 DevKit wired to the existing driver shield's step/dir pins. Motion values are copied from the Uno's live settings (`../backup/grbl-settings-2026-11-15.txt`, read 2026-11-15: GRBL 1.1h, variable spindle, homing on).

- **Not stock X-Carve electronics.** Belt axes use 80 steps/mm, which means 1/16 microstepping, so the shield is likely a CNC Shield V3 (A4988/DRV8825). A gShield runs at 1/8. Z is 1505 steps/mm and the machine runs slow: 800 mm/min, 10 mm/s² acceleration.
- **Uno is OK.** It answered over USB, so the Nov 2025 "not accessible" error just meant it was unplugged from the Pi.

## ESP32 status (2026-11-15)

- **Board:** ESP32-D0WD-V3 (rev 3.1) WROOM-32 DevKit, CP2102 USB, 4 MB flash.
- **Firmware:** FluidNC **v4.1.1** (stable, 2026-09-25), Wi-Fi build. Installer files are in `fluidnc/release-v4.1.1/`. v4.1 also made S3 support stable, but the classic ESP32 is still the pick here.
- **Wi-Fi:** joined the workshop Wi-Fi. Web UI at http://xcarve.local (192.168.1.115), Telnet on port 23.
- **Config:** `../fluidnc/config.yaml` loaded with no errors. Control pins (hold/start/macro) are disabled until pull-ups are wired.
- **Tip:** opening the USB port resets the board on macOS. Send commands over HTTP instead: `curl -G --data-urlencode 'plain=?' http://xcarve.local/command`.
- **Next:** wire the board per `WIRING.md`, then bench test.
