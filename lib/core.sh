#!/usr/bin/env bash
# Coded by Cyber Security Engineer Mr Sabaz Ali Khan
safe_text() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
heading() { printf '\n--- %s ---\n' "$1"; }
need() { command -v "$1" >/dev/null 2>&1 || { printf 'Missing dependency: %s. Run bash setup.sh for guidance.\n' "$1" >&2; return 1; }; }
# NetworkManager escapes colons and backslashes in terse output.
parse_row() {
    FIELDS=(); local s=$1 c field='' escaped=0 i
    for ((i=0; i<${#s}; i++)); do
        c=${s:i:1}
        if ((escaped)); then field+=$c; escaped=0
        elif [[ $c == \\ ]]; then escaped=1
        elif [[ $c == : ]]; then FIELDS+=("$field"); field=''
        else field+=$c; fi
    done
    FIELDS+=("$field")
}
choose_iface() {
    [[ $DEMO == 1 ]] && { IFACE=wlan0; return; }
    need nmcli || return 1
    local rows dev type state
    rows=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>&1) || { printf '%s\n' "$rows" | safe_text; return 1; }
    while IFS= read -r row; do
        parse_row "$row"; dev=${FIELDS[0]:-}; type=${FIELDS[1]:-}; state=${FIELDS[2]:-}
        if [[ $type == wifi && ( -z $IFACE || $IFACE == "$dev" ) ]]; then IFACE=$dev; return 0; fi
    done <<< "$rows"
    printf 'No matching Wi-Fi interface. Check nmcli device status, rfkill, or USB passthrough in your VM.\n' >&2
    return 1
}
scan_rows() {
    if [[ $DEMO == 1 ]]; then
        printf '%s\n' '*:HomeLab:02\:00\:00\:00\:00\:01:6:82:WPA2 WPA3' ':GuestLab:02\:00\:00\:00\:00\:02:6:53:--' ':LegacyLab:02\:00\:00\:00\:00\:03:11:37:WEP'
        return
    fi
    choose_iface || return 1
    nmcli --wait 15 -t --escape yes -f IN-USE,SSID,BSSID,CHAN,SIGNAL,SECURITY device wifi list ifname "$IFACE" --rescan auto
}
discover() {
    heading 'Nearby access points'
    local rows row
    rows=$(scan_rows) || return 1
    printf '%-3s %-28s %-19s %-5s %-7s %s\n' 'USE' 'SSID' 'BSSID' 'CH' 'SIGNAL' 'SECURITY'
    while IFS= read -r row; do
        [[ -n $row ]] || continue
        parse_row "$row"
        printf '%-3s %-28s %-19s %-5s %-7s %s\n' "${FIELDS[0]:-}" "${FIELDS[1]:-(hidden)}" "${FIELDS[2]:-}" "${FIELDS[3]:-}" "${FIELDS[4]:-}" "${FIELDS[5]:-}" | safe_text
    done <<< "$rows"
    printf 'Signal is a NetworkManager percentage, not distance. Results may be cached.\n'
}
security_label() {
    local sec=${1^^}
    case "$sec" in
        ''|'--') printf 'REVIEW: no link encryption advertised' ;;
        *WEP*) printf 'HIGH: obsolete WEP advertised' ;;
        *WPA3*) printf 'INFO: WPA3 advertised; verify router mode and passphrase' ;;
        *WPA2*) printf 'INFO: WPA2 advertised; verify AES/CCMP and passphrase' ;;
        *OWE*) printf 'INFO: enhanced open encryption; no network authentication' ;;
        *WPA1*|WPA) printf 'HIGH: legacy WPA advertised' ;;
        *) printf 'UNKNOWN: inspect router settings' ;;
    esac
}
audit() {
    heading 'Connected access point security review'
    local rows row found=0
    rows=$(scan_rows) || return 1
    while IFS= read -r row; do
        parse_row "$row"
        [[ ${FIELDS[0]:-} == '*' ]] || continue
        found=1
        printf 'SSID: %s\nAdvertised security: %s\n' "${FIELDS[1]:-(hidden)}" "${FIELDS[5]:-unknown}" | safe_text
        security_label "${FIELDS[5]:-}"; printf '\n'
        if [[ ${FIELDS[5]:-} == *WPA1* ]]; then printf 'REVIEW: legacy WPA1 is also advertised.\n'; fi
        if [[ ${FIELDS[5]:-} == *WPA2* && ${FIELDS[5]:-} == *WPA3* ]]; then printf 'REVIEW: WPA2/WPA3 transition mode is advertised.\n'; fi
    done <<< "$rows"
    ((found)) || printf 'No connected access point found in scan results.\n'
    printf 'This is an advertised-configuration review, not proof a network is secure.\n'
    checklist
}
checklist() {
    heading 'Router checks to perform manually'
    cat <<'TEXT'
[ ] Use WPA3-Personal where supported, or WPA2 with AES/CCMP.
[ ] Use a long, unique Wi-Fi passphrase and a separate router admin password.
[ ] Disable WPS and unnecessary remote administration.
[ ] Keep router firmware updated; replace unsupported equipment.
[ ] Isolate guest and IoT devices; review the router client list.
[ ] Review DNS, firewall, and backup settings in the router admin page.
WPS, firmware, password strength, and router firewall status are not verified here.
TEXT
}
status() {
    heading 'Interface and connection details'
    if [[ $DEMO == 1 ]]; then printf 'DEMO: wlan0 / HomeLab / 192.0.2.10/24 / gateway 192.0.2.1\n'; return; fi
    choose_iface || return 1
    nmcli -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show "$IFACE" | safe_text
}
neighbors() {
    heading 'Locally observed neighbor cache'
    if [[ $DEMO == 1 ]]; then printf 'DEMO: 192.0.2.1 lladdr 02:00:00:00:00:01 REACHABLE\n'; return; fi
    choose_iface || return 1; need ip || return 1
    ip neigh show dev "$IFACE" | safe_text
    printf 'Cache entries are not a full router client list and do not prove ownership.\n'
}
diagnostics() {
    status || return 1
    heading 'Gateway reachability (3 ICMP packets)'
    if [[ $DEMO == 1 ]]; then printf 'DEMO: 3 transmitted, 3 received, 0%% loss\n'; return; fi
    need ip || return 1; need ping || return 1
    local gateway
    gateway=$(ip -4 route show default dev "$IFACE" | awk '/via/ {print $3; exit}')
    [[ -n $gateway ]] || { printf 'No IPv4 default gateway on this interface.\n'; return 1; }
    ping -n -I "$IFACE" -c 3 -W 2 "$gateway" || { printf 'No complete reply: ICMP may be filtered; this alone does not prove an outage.\n'; return 1; }
}
channels() {
    heading 'Observed access points per channel'
    local rows row
    rows=$(scan_rows) || return 1
    while IFS= read -r row; do
        [[ -n $row ]] || continue; parse_row "$row"
        [[ ${FIELDS[3]:-} =~ ^[0-9]+$ ]] && printf '%s\n' "${FIELDS[3]}"
    done <<< "$rows" | sort -n | uniq -c | awk '{printf "Channel %-4s %s AP(s)\n", $2, $1}'
    printf 'AP counts do not measure airtime utilization or interference.\n'
}
monitor() {
    local count=${1:-12} i rows row found
    [[ $count =~ ^[0-9]+$ && ${#count} -le 4 ]] && ((10#$count >= 1 && 10#$count <= 720)) || { printf 'Samples must be 1-720.\n' >&2; return 1; }
    heading 'Signal monitor (5-second interval; Ctrl+C stops)'
    for ((i=0; i<10#$count; i++)); do
        rows=$(scan_rows) || return 1; found=0
        while IFS= read -r row; do
            parse_row "$row"; [[ ${FIELDS[0]:-} == '*' ]] || continue; found=1
            printf '%s  %s  signal=%s%%  channel=%s\n' "$(date '+%H:%M:%S')" "${FIELDS[1]:-}" "${FIELDS[4]:-}" "${FIELDS[3]:-}" | safe_text
        done <<< "$rows"
        ((found)) || printf '%s disconnected or absent from scan cache\n' "$(date '+%H:%M:%S')"
        ((i+1 < 10#$count)) && sleep 5
    done
    return 0
}
report() {
    local dir=${XDG_STATE_HOME:-${HOME:?}/.local/state}/wifi-guard-sabaz path failed=0
    mkdir -p -- "$dir" || return 1
    path=$(mktemp "$dir/report-$(date '+%Y%m%d-%H%M%S')-XXXXXX.txt") || return 1
    {
        printf 'WiFi Guard Sabaz 1.0\nCoded by Cyber Security Engineer Mr Sabaz Ali Khan\nCreated: %s\nDemo mode: %s\n' "$(date -Is)" "$DEMO"
        for section in status discover audit channels neighbors; do
            "$section" || { printf '[INCOMPLETE] Section failed: %s\n' "$section"; failed=1; }
        done
        printf '\nIncomplete sections: %s\n' "$failed"
    } > "$path"
    printf 'Report saved: %s\nContains network identifiers; review before sharing.\n' "$path"
}
