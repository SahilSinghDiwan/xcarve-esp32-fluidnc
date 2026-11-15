# X-Carve: Raspberry Pi + Arduino Uno → one ESP32 (FluidNC)

This replaces an X-Carve CNC controller stack with a single ESP32 running [FluidNC](https://github.com/bdring/FluidNC).

- **Old stack:** Raspberry Pi running CNCjs → USB → Arduino Uno running GRBL 1.1h → Arduino CNC Shield.
- **New stack:** ESP32 running FluidNC → the **same** CNC Shield.

The ESP32 does the Uno's motion control and serves its own Wi-Fi control page, which replaces the Pi and CNCjs. Motors, drivers, limit switches, spindle and power supply stay as they are.

> **Status (2026-11-15): reviewed on the bench, not yet tested on the machine.** FluidNC v4.1.1 is flashed on an ESP32 and joined to Wi-Fi, and the machine config loads with no errors. The shield is not wired yet and no motor has moved. This repo is up for review before wiring.

## Repo map

| Path | What |
|---|---|
| [`docs/FINDINGS.md`](docs/FINDINGS.md) | Audit of the old Pi: what ran, evidence, why ESP32 (not S3) |
| [`docs/WIRING.md`](docs/WIRING.md) | ESP32 → CNC Shield pin map, diagram, safety rules, bench order |
| [`docs/PROCESS.md`](docs/PROCESS.md) | Step-by-step log of everything done, and how it was kept non-destructive |
| [`fluidnc/config.yaml`](fluidnc/config.yaml) | FluidNC machine config (values from the Uno's live `$$`) |
| [`backup/grbl-settings-2026-11-15.txt`](backup/grbl-settings-2026-11-15.txt) | The Uno's original GRBL settings (source of truth) |
| [`tools/`](tools) | Scripts for flashing, Wi-Fi setup, config upload, sending commands, SD audit |

## Try it on your own ESP32 (no machine needed, ~10 min)

You need a classic **ESP32-WROOM-32 DevKit** with 4 MB flash (an S3 needs a different build), a USB cable, and Python with `esptool` and `pyserial`. PlatformIO's copies are used automatically if installed.

```bash
git clone <this repo> && cd <repo>
ls /dev/cu.usbserial* /dev/ttyUSB* 2>/dev/null           # find the port
tools/flash-fluidnc.sh /dev/cu.usbserial-XXXX            # erases the ESP32 and flashes FluidNC v4.1.1
tools/set-wifi.sh /dev/cu.usbserial-XXXX "<your-ssid>"   # asks for the password; hostname becomes xcarve
tools/upload-config.sh                                   # uploads fluidnc/config.yaml, reboots, prints status
```

Expected result:
- `<Idle|MPos:0.000,0.000,0.000|...>`
- http://xcarve.local opens the FluidNC web UI. Use `HOST=<ip>` with the scripts if `.local` names don't resolve on your network.
- Send any command with `tools/fluidnc-cmd.sh '$LocalFS/List'`.

## What to review

1. **Pin choices** in [`docs/WIRING.md`](docs/WIRING.md). They avoid ESP32 boot-mode pins (0, 2, 12, 15) and input-only pins for outputs.
2. **Shield 5V rail fed from the ESP32's 3V3.** This lets A4988 drivers accept 3.3 V step/dir signals and keeps 5 V away from the ESP32.
3. **D11/D12 swap.** In GRBL 1.1 the Z limit is on D12 and spindle PWM on D11, so the shield's printed labels are misleading.
4. **Motion values** in `config.yaml` against [`backup/grbl-settings-2026-11-15.txt`](backup/grbl-settings-2026-11-15.txt).
5. **Control inputs (hold/start/macro) are disabled** until pull-ups are added.

## Not in git

- `backup/rootfs.img`: 30 GB image of the Pi's SD card, kept on the audit machine.
- `fluidnc/release-*`: FluidNC downloads, which `tools/flash-fluidnc.sh` fetches again.
- No Wi-Fi credentials are stored anywhere in this repo.
