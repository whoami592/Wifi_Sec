#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
source "$ROOT/lib/core.sh"
parse_row '*:Lab\:Room\\One:02\:00\:00\:00\:00\:01:6:80:WPA2'
[[ ${#FIELDS[@]} == 6 && ${FIELDS[1]} == 'Lab:Room\One' && ${FIELDS[2]} == '02:00:00:00:00:01' ]]
[[ $(security_label WEP) == HIGH:* ]]
[[ $(security_label --) == REVIEW:* ]]
[[ $(security_label 'WPA2 WPA3') == INFO:* ]]
[[ $(printf 'safe\033[31m\007' | safe_text) == 'safe[31m' ]]
for cmd in scan status audit channels neighbors diagnose checklist; do
    bash "$ROOT/wifi_guard.sh" --demo "$cmd" >/dev/null
done
bash "$ROOT/wifi_Sec.sh" --demo monitor 1 >/dev/null
if bash "$ROOT/wifi_Sec.sh" --demo monitor 0 >/dev/null 2>&1; then exit 1; fi
if bash "$ROOT/wifi_Sec.sh" --interface >/dev/null 2>&1; then exit 1; fi
if bash "$ROOT/wifi_Sec.sh" unknown >/dev/null 2>&1; then exit 1; fi
printf '1\n3\n0\n' | bash "$ROOT/wifi_Sec.sh" --demo >/dev/null
TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT
XDG_STATE_HOME="$TEMP_DIR" bash "$ROOT/wifi_Sec.sh" --demo report >/dev/null
reports=("$TEMP_DIR"/wifi-Sec-sabaz/*.txt)
[[ -f ${reports[0]} && $(stat -c %a "${reports[0]}") == 600 ]]
rg -q 'Incomplete sections: 0' "${reports[0]}"
# Mock NetworkManager to exercise live-path parsing and disconnected handling.
mkdir "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/nmcli" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
    *'DEVICE,TYPE,STATE device status'*) printf 'wlan0:wifi:connected\n' ;;
    *'device wifi list'*) printf '%s\n' '*:Test\:Lab:02\:00\:00\:00\:00\:01:1:75:WPA2' ;;
    *) exit 1 ;;
esac
MOCK
chmod +x "$TEMP_DIR/bin/nmcli"
PATH="$TEMP_DIR/bin:$PATH" bash "$ROOT/wifi_Sec.sh" scan > "$TEMP_DIR/scan.txt"
rg -q 'Test:Lab' "$TEMP_DIR/scan.txt"
if PATH="$TEMP_DIR/bin:$PATH" bash "$ROOT/wifi_Sec.sh" --interface nope scan >/dev/null 2>&1; then exit 1; fi
printf 'PASS: parser, security labels, terminal sanitization, demo commands, menu, validation, private reports, mocked NetworkManager.\n'
