#!/usr/bin/env bash
set -u
printf 'WiFi Guard Sabaz - dependency check\n'
missing=0
for tool in bash nmcli ip ping awk sort uniq tr mktemp date; do
    if command -v "$tool" >/dev/null 2>&1; then printf '[OK] %s\n' "$tool"
    else printf '[MISSING] %s\n' "$tool"; missing=1; fi
done
if ((missing)); then
    printf '\nFor Kali / Ubuntu / Debian, install dependencies yourself:\n  sudo apt update\n  sudo apt install network-manager iproute2 iputils-ping coreutils gawk\n'
fi
printf '\nRun: bash wifi_guard.sh\nOffline demo: bash wifi_guard.sh --demo\nNetworkManager must already manage your Wi-Fi adapter.\n'
exit "$missing"
