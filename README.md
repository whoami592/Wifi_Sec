# WiFi Guard Sabaz

**Coded by Cyber Security Engineer Mr Sabaz Ali Khan**

A terminal-only Bash Wi-Fi security and diagnostics project. No GUI, Python, API key, or root session required. Designed for Kali Linux, Ubuntu, and Debian with Bash 4+ and NetworkManager.

## Quick start

Extract the ZIP, open a Linux terminal inside this folder, and run:

```bash
bash setup.sh
bash wifi_guard.sh
```

If dependencies are missing on Kali/Ubuntu/Debian:

```bash
sudo apt update
sudo apt install network-manager iproute2 iputils-ping coreutils gawk
```

The setup script only checks dependencies and prints guidance; it does not install packages or change networking. NetworkManager must be running and managing the adapter. Run the toolkit as your normal user.

## Features

- Numbered terminal menu and scriptable commands.
- Nearby access points: SSID, BSSID, channel, signal percentage, advertised encryption.
- Connected access point review: open, WEP, legacy WPA, WPA2, WPA3 and transition-mode observations.
- Local interface, IPv4 address, gateway and DNS details.
- Channel counts, with clear measurement limitations.
- Local neighbor cache (no network-wide host scan).
- Three-packet gateway ping diagnostics.
- Bounded signal monitoring with five-second intervals.
- Timestamped text reports with owner-only permissions.
- Manual router hardening checklist.
- Fully offline demo with visibly fictional data.
- English interface and documentation throughout.

## Commands

```bash
bash wifi_guard.sh --demo
bash wifi_guard.sh scan
bash wifi_guard.sh --interface wlan0 status
bash wifi_guard.sh audit
bash wifi_guard.sh channels
bash wifi_guard.sh neighbors
bash wifi_guard.sh diagnose
bash wifi_guard.sh monitor 12
bash wifi_guard.sh report
bash wifi_guard.sh checklist
bash wifi_guard.sh --help
```

Options go before the command. Replace `wlan0` with the adapter from `nmcli device status`. If multiple adapters exist, specify one; otherwise the first Wi-Fi adapter is selected. Monitor accepts 1-720 samples; press Ctrl+C to exit the program. Scans use NetworkManager's automatic rescan behavior, so readings can be cached and do not guarantee a fresh scan every five seconds.

Reports are saved in `$XDG_STATE_HOME/wifi-guard-sabaz`, or `~/.local/state/wifi-guard-sabaz` when that variable is unset. The command prints the exact filename. Reports include network identifiers and local IP information, but do not request or export Wi-Fi passwords. Failed report sections are marked INCOMPLETE. Reports do not run gateway pings automatically.

## Windows and virtual machines

Use native Linux or a Linux VM with a compatible USB Wi-Fi adapter passed through. Git Bash does not provide Linux NetworkManager. WSL normally exposes a virtual network interface, not your physical Wi-Fi radio; live Wi-Fi features generally will not work there. Demo mode works without Wi-Fi hardware wherever the required Bash/basic Unix utilities are available.

## Troubleshooting

- **No matching interface:** run `nmcli device status` and check USB adapter passthrough. A VM's virtual Ethernet adapter is not a Wi-Fi adapter.
- **NetworkManager unavailable:** check `systemctl status NetworkManager`. Avoid switching network managers blindly, particularly on a remote session.
- **Radio disabled:** inspect `rfkill list` and `nmcli radio wifi`; enable Wi-Fi using your normal system controls.
- **No scan results:** check adapter support, radio state and NetworkManager permissions. The program does not change monitor mode or connect/disconnect networks.
- **No active access point:** connect through your usual network controls, then rerun audit.
- **Ping fails:** gateways can block ICMP. Do not infer a network outage from ping alone.
- **Empty neighbors:** this is only your machine's existing cache. See your router's admin client list for a fuller view.

## Scope and interpretation

Use diagnostics on networks you own or administer. Discovery reads the access points visible to the adapter; NetworkManager may send normal Wi-Fi probe requests. This is not a fully passive radio capture tool. No password cracking, deauthentication, packet capture, credential collection, or router setting changes are included.

Advertised encryption is not the same as the cipher actually negotiated. WPA2/WPA3 labels alone cannot verify firmware, passphrase quality, WPS state, firewall status, or overall security. AP counts per channel do not measure utilization, overlap, bandwidth, or interference. Signal percentage is not distance. Duplicate SSIDs can be legitimate mesh/extender deployments; the toolkit makes no evil-twin detection claim.

## Project structure

```text
WiFi_Guard_Sabaz/
  wifi_guard.sh       Entry point and menu
  setup.sh            Dependency checker
  lib/core.sh         Discovery, diagnostics, audit and reports
  tests/test.sh       Offline regression checks
  README.md           Setup and usage
  TESTING.md          Validation and limitations
```

## Tests

```bash
bash tests/test.sh
```

Tests additionally require `rg` (ripgrep) and GNU `stat`. Live hardware validation must be performed on your own Linux machine. To remove the app, delete its extracted folder; reports remain in the state directory described above.
