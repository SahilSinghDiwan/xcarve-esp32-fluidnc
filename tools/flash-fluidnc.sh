#!/usr/bin/env bash
# Flash FluidNC (Wi-Fi build) onto a classic ESP32 (WROOM-32, 4 MB flash).
# Usage: tools/flash-fluidnc.sh /dev/cu.usbserial-XXXX [version]
# Needs esptool: PlatformIO's copy is used if present, else `esptool.py` on PATH (pip install esptool).
# ERASES the whole ESP32 flash.
set -euo pipefail
PORT=${1:?serial port, e.g. /dev/cu.usbserial-0001 or /dev/ttyUSB0}
VER=${2:-v4.1.1}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIR="$ROOT/fluidnc/release-$VER"
if [ ! -d "$DIR/unz" ]; then
  mkdir -p "$DIR"
  curl -fL -o "$DIR/fluidnc.zip" "https://github.com/bdring/FluidNC/releases/download/$VER/fluidnc-$VER-posix.zip"
  unzip -q -o "$DIR/fluidnc.zip" -d "$DIR/unz"
fi
B=$(echo "$DIR"/unz/fluidnc-*-posix)
PIO="$HOME/.platformio/packages/tool-esptoolpy/esptool.py"
if [ -f "$PIO" ]; then ESPTOOL=("$HOME/.platformio/penv/bin/python" "$PIO"); else ESPTOOL=(esptool.py); fi
E(){ "${ESPTOOL[@]}" --chip esp32 --port "$PORT" --baud 460800 "$@"; }
E flash_id
E erase_flash
E --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size detect \
  0x1000 "$B/wifi/bootloader.bin" 0x8000 "$B/wifi/partitions.bin" 0xe000 "$B/common/boot_app0.bin" \
  0x10000 "$B/wifi/firmware.bin" 0x3d0000 "$B/wifi/littlefs.bin"
echo "Flashed FluidNC $VER. Next: tools/set-wifi.sh $PORT <ssid>"
