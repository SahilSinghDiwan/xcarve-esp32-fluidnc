# Legacy Raspberry Pi files (rescued from the SD card)

Small files kept from the Pi's SD card before its 30 GB backup image was deleted (2026-11-15). They're for reference only. None of them run on the ESP32.

| Path | What | ESP32/FluidNC equivalent |
|---|---|---|
| `cncjs-pendant-raspi-gpio/` | Button on GPIO4 and LED on GPIO17 sending hold, coolant, `$X`, `$SLP` and `$H` to CNCjs. Includes local edits. | `control:` pins + `macros:` in `fluidnc/config.yaml` (disabled until pull-ups are fitted) |
| `cncjs-pendant-powersense/` | Power-loss sense on GPIO4: `!` (hold) when power drops, `~` (resume) when it returns | `feed_hold_pin` |
| `cncjs-pendant-keyboard/` | USB keyboard jog via node-hid | FluidNC web UI jog |
| `pi-config/cncrc.json` | CNCjs settings + macro "Go to top left" = `G0 X0 Y320`. The password hash was removed. | Add as a web UI macro |
| `pi-config/pm2-apps.json` | How CNCjs was started at boot | Not needed |
| `pi-config/iptables-rules.v4` | Port 80 → 8000 redirect for CNCjs | FluidNC serves on port 80 directly |
| `pi-config/hostname` | `xcarve` | `$Hostname=xcarve` (already set) |
| `pi-config/time_lapse_capture.py` | Pi camera photo every 5 min | None (would need an ESP32-CAM) |

The pendant folders are open-source CNCjs pendant projects, each with its own `LICENSE`. They were copied without `node_modules` or docs images.

**Not found on the card:** no Arduino sketch, GRBL `.hex` file, or G-code files. GRBL 1.1h exists only on the Uno, which is unchanged. Its settings are in `../backup/grbl-settings-2026-11-15.txt`.

**Left out on purpose:**
- the Easel driver (Inventables software, re-downloadable)
- the ChiliPeppr serial-port-json-server (a third-party binary)
- shell history
- personal photos and files unrelated to the CNC
