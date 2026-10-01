# Validation

Automated checks passed in the build environment:

- Bash syntax validation for every shell file.
- Escaped colons/backslashes in NetworkManager output.
- Security label classification and terminal control-character removal.
- Every noninteractive demo feature and a one-sample monitor.
- Menu scan/audit/exit flow.
- Invalid command, missing interface argument, invalid monitor count.
- Report creation, complete section markers, and mode 600 permissions.
- Mocked NetworkManager discovery with a colon-containing SSID.
- Rejection of a nonexistent selected interface.

Not tested here: physical Wi-Fi scanning, real adapter drivers, NetworkManager policy permissions, real gateway ping, and radio behavior. Validate those on the target Linux system. Demo data is fictional and clearly labeled.
