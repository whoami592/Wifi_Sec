#!/usr/bin/env bash
# Coded by Cyber Security Engineer Mr Sabaz Ali Khan
set -uo pipefail
umask 077
export LC_ALL=C
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$ROOT/lib/core.sh"
DEMO=0 IFACE=''
usage() {
    cat <<'HELP'
WiFi Sec - terminal Wi-Fi security toolkit
Coded by Cyber Security Engineer Mr Sabaz Ali Khan
Usage: bash wifi_guard.sh [--demo] [--interface NAME] [COMMAND] [SAMPLES]
Commands: menu (default), scan, status, audit, channels, neighbors,
          diagnose, monitor [1-720 samples], report, checklist, help
Linux + Bash 4+ + NetworkManager. Use on networks you own or administer.
HELP
}
while (($#)); do
    case "$1" in
        --demo) DEMO=1; shift ;;
        --interface) [[ $# -ge 2 && -n $2 ]] || { usage; exit 2; }; IFACE=$2; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        --*) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
        *) break ;;
    esac
done
[[ -z $IFACE || $IFACE =~ ^[a-zA-Z0-9_.:-]+$ ]] || { printf 'Invalid interface name.\n' >&2; exit 2; }
[[ $DEMO == 0 ]] || printf '[DEMO MODE: all network data is fictional]\n'
run_command() {
    case "$1" in
        scan) discover ;; status) status ;; audit) audit ;; channels) channels ;;
        neighbors) neighbors ;; diagnose) diagnostics ;; monitor) monitor "${2:-12}" ;;
        report) report ;; checklist) checklist ;; help) usage ;;
        *) printf 'Unknown command: %s\n' "$1" >&2; return 2 ;;
    esac
}
menu() {
    local choice cmd
    usage
    while :; do
        printf '\n1) Wi-Fi scan    2) Connection status    3) Security review\n4) Channels     5) Neighbor cache       6) Diagnostics\n7) Signal monitor  8) Save report       9) Router checklist\n0) Exit\n'
        read -r -p 'Select an option: ' choice || break
        case "$choice" in
            1) cmd=scan ;; 2) cmd=status ;; 3) cmd=audit ;; 4) cmd=channels ;;
            5) cmd=neighbors ;; 6) cmd=diagnose ;; 7) cmd=monitor ;; 8) cmd=report ;;
            9) cmd=checklist ;; 0) break ;; *) printf 'Choose 0-9.\n'; continue ;;
        esac
        run_command "$cmd" || printf 'Action could not complete. Check the message above.\n'
    done
}
if [[ ${1:-menu} == menu ]]; then menu; else run_command "$@"; fi
