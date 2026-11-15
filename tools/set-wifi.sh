#!/usr/bin/env bash
# Put FluidNC on your Wi-Fi over USB. Password is prompted, never stored.
# Usage: tools/set-wifi.sh /dev/cu.usbserial-XXXX <ssid> [hostname]
set -euo pipefail
PORT=${1:?serial port}; SSID=${2:?wifi ssid}; HOST=${3:-xcarve}
read -rsp "Wi-Fi password for $SSID: " PASS; echo
PY="$HOME/.platformio/penv/bin/python"; [ -x "$PY" ] || PY=python3   # needs pyserial
PORT="$PORT" SSID="$SSID" PASS="$PASS" HOST="$HOST" "$PY" -I - <<'PYEOF'
import os, serial, time
s = serial.Serial(os.environ['PORT'], 115200, timeout=0.3)
# Opening the port resets the ESP32: wait for FluidNC's ready banner (first boot after flashing is slower).
boot, t = b'', time.time()
while b'Grbl' not in boot and time.time() - t < 15:
    boot += s.read(4096)
if b'Grbl' not in boot:
    s.write(b'\n'); time.sleep(1); boot += s.read(4096)
if b'Grbl' not in boot and b'ok' not in boot:
    raise SystemExit('FluidNC did not answer on ' + os.environ['PORT'] + '. Is it flashed? Try again or replug.')
time.sleep(0.5); s.read(65536)
for c in (f"$Sta/SSID={os.environ['SSID']}", f"$Sta/Password={os.environ['PASS']}",
          "$WiFi/Mode=STA", f"$Hostname={os.environ['HOST']}"):
    s.write(c.encode() + b"\n"); time.sleep(0.5)
    print(c.split('=')[0], '->', s.read(4096).decode(errors='replace').strip())
s.write(b"$Bye\n"); time.sleep(10)
out = s.read(65536).decode(errors='replace')
print('\n'.join(l for l in out.splitlines() if 'STA' in l or 'IP' in l or 'mDNS' in l))
PYEOF
