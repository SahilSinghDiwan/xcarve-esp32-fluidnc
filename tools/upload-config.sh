#!/usr/bin/env bash
# Upload fluidnc/config.yaml to the ESP32 over Wi-Fi, reboot it, and show the result.
# Usage: tools/upload-config.sh   (HOST=<ip> to override xcarve.local)
set -euo pipefail
HOST=${HOST:-xcarve.local}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
curl -fs -m 20 -F "myfile=@$ROOT/fluidnc/config.yaml;filename=config.yaml" "http://$HOST/files?path=/" >/dev/null
echo "uploaded config.yaml"
curl -s -m 5 -G --data-urlencode 'plain=$Bye' "http://$HOST/command" >/dev/null || true
sleep 12
curl -s -m 10 -G --data-urlencode 'plain=?' "http://$HOST/command"; echo
