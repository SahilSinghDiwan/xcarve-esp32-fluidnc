#!/usr/bin/env bash
# Put the ESP32 back exactly as it was on 2026-11-15: FluidNC v4.1.1 + config.yaml + Wi-Fi + hostname.
# Writes the full 4 MB flash image taken from the working board (backup/, not in git: holds Wi-Fi creds).
# Usage: tools/restore-esp32.sh [port]   (port auto-detected if only one USB serial device)
# Without the image (e.g. a fresh clone), rebuild instead:
#   tools/flash-fluidnc.sh <port> && tools/set-wifi.sh <port> <ssid> && tools/upload-config.sh
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMG="$ROOT/backup/esp32-xcarve-fluidnc-v4.1.1-full.bin"
PORT=${1:-$(ls /dev/cu.usbserial-* /dev/cu.SLAB_USBtoUART /dev/ttyUSB* 2>/dev/null | head -1)}
[ -n "$PORT" ] || { echo "No ESP32 serial port found; plug it in or pass the port."; exit 1; }
[ -f "$IMG" ] || { echo "Image missing: $IMG (use the rebuild steps in this script's header)"; exit 1; }
(cd "$ROOT/backup" && shasum -a 256 -c "$(basename "$IMG").sha256")
PIO="$HOME/.platformio/packages/tool-esptoolpy/esptool.py"
if [ -f "$PIO" ]; then ESPTOOL=("$HOME/.platformio/penv/bin/python" "$PIO"); else ESPTOOL=(esptool.py); fi
"${ESPTOOL[@]}" --chip esp32 --port "$PORT" --baud 921600 write_flash --flash_mode keep --flash_freq keep --flash_size keep 0x0 "$IMG"
"${ESPTOOL[@]}" --chip esp32 --port "$PORT" --baud 921600 verify_flash 0x0 "$IMG"
echo "Restored. Give it ~10 s, then open http://xcarve.local"
