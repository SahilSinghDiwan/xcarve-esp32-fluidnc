# What was done, in order (2026-11-15)

Every step on the old hardware was **read-only**. Nothing on the Pi's SD card or the Uno was changed.

## 1. Audit the Pi's SD card without mounting it

- **The card:** 32 GB, with a 45 MB FAT `boot` partition and an ext4 root partition.
  - macOS mounts only `boot`. It holds Raspbian Stretch from 2019-04-08 and nothing CNC-specific.
  - macOS can't mount ext4. The raw partition is root-only, so the only change made was `sudo chmod o+r /dev/rdiskNs2`, which adds read permission and resets when the card is unplugged.
- **The copy:** a full `dd` would have taken about 66 min (the card reader runs at 8 MB/s). Instead, [`tools/sd-used-blocks-copy.py`](../tools/sd-used-blocks-copy.py) reads the ext4 block bitmaps and copies only allocated blocks (8.34 GB) into a sparse image. That took about 17 min.
- **Checking the copy:** the image was made read-only. `e2fsck -fn` (check only) reported it clean, and its block count matched the superblock.
- **Reading files:** done with `debugfs -c` (catastrophic/read-only mode) inside a Debian Docker container, with the image mounted `:ro`.
- **Side effect:** macOS itself created its usual hidden `.fseventsd` folder on the FAT `boot` partition when the card was inserted. That's harmless to the Pi.

Findings are in [FINDINGS.md](FINDINGS.md). In short:
- **Software:** CNCjs 1.9.20 under pm2 on port 8000, with port 80 redirected to it. It talked to the Uno on `/dev/ttyACM0`.
- **Machine and extras:** hostname `xcarve`, with custom GPIO and keyboard pendants and a Pi camera time-lapse.
- **History:** last real use was June 2022.

## 2. Read the Uno's settings

The Uno was connected to the Mac over USB, with the shield still on and motor power off. Only two commands were sent with pyserial: `$I` (build info) and `$$` (settings). Neither one moves the machine or writes anything.

- **Firmware:** GRBL **1.1h**, with options `V` (variable spindle).
- **Settings:** saved to [`../backup/grbl-settings-2026-11-15.txt`](../backup/grbl-settings-2026-11-15.txt).
- **Driver shield:** 80 steps/mm on belts means 1/16 microstepping. That points to a generic Arduino CNC Shield (V3 style) with A4988/DRV8825 drivers, which the owner confirmed. It is not a gShield.

## 3. Choose the board

- **Plain ESP32 + FluidNC.** FluidNC is the successor to Grbl_ESP32. It runs motion control and the web UI on one chip, and its long-proven target is the classic ESP32.
- **The S3 isn't needed.** FluidNC v4.1 (Sept 2026) made S3 support stable, but this machine gains nothing from it.

## 4. Wiring and config

- **Wiring:** [WIRING.md](WIRING.md) maps the ESP32 pins to the shield's Uno header pins, so the shield and all field wiring stay.
- **Config:** [`../fluidnc/config.yaml`](../fluidnc/config.yaml) uses the values copied from step 2:
  - steps/mm, rates, acceleration and travel
  - homing directions (`$23=3` → X/Y home toward negative)
  - homing feed/seek/pulloff, the step pulse (10 µs) and the idle delay (25 ms)
  - spindle PWM scaled to 0–12000 RPM

## 5. Flash the ESP32

1. **Identify the board:** `esptool flash_id` reported an ESP32-D0WD-V3 rev 3.1 with 4 MB flash and a CP2102 USB bridge. It shipped with Espressif's AT firmware.
2. **Wi-Fi test on AT firmware:** couldn't work over USB, because that firmware only takes commands on UART1 (GPIO16/17).
3. **Flash FluidNC v4.1.1:** erased the chip, then wrote the Wi-Fi build. All five images passed hash verification. This is now [`../tools/flash-fluidnc.sh`](../tools/flash-fluidnc.sh).
4. **Join Wi-Fi:** set `$Sta/SSID`, `$Sta/Password` and `$WiFi/Mode=STA`, rebooted, and it connected. This is now [`../tools/set-wifi.sh`](../tools/set-wifi.sh).
5. **Upload the config:** sent `config.yaml` over HTTP and rebooted. The boot log showed every axis, pin, the spindle and the probe exactly as configured, with no errors. State: `Idle`.
6. **Set the hostname:** `$Hostname=xcarve`, so http://xcarve.local works like the old Pi did.

Found while doing this:
- **USB resets the board.** On macOS, opening the CP2102 port toggles DTR/RTS and resets the ESP32. Use the HTTP command API instead ([`../tools/fluidnc-cmd.sh`](../tools/fluidnc-cmd.sh)).
- **Control pins were disabled.** GPIO 34/36/39 have no internal pull-ups and would float. The hold/start/macro inputs stay disabled until 10 kΩ pull-ups are fitted.

## 6. Still to do

1. Get this repo reviewed.
2. Wire the board per [WIRING.md](WIRING.md), leaving motor power off.
3. Check each limit switch shows up in `?` status over Wi-Fi.
4. Turn motor power on and jog each axis 1 mm at a time.
5. Set `must_home: true` once homing is verified.

The Uno and its EEPROM settings are untouched. Putting the shield back on the Uno restores the old setup completely.
