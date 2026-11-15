#!/usr/bin/env bash
# Send one command to FluidNC over Wi-Fi (does not reset the board, unlike USB on macOS).
# Usage: tools/fluidnc-cmd.sh '?'   |   HOST=192.168.1.115 tools/fluidnc-cmd.sh '$LocalFS/List'
HOST=${HOST:-xcarve.local}
curl -s -m 10 -G --data-urlencode "plain=${1:?command}" "http://$HOST/command"; echo
