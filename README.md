# Serpantinum Power for Omarchy

An animated, Omarchy-native battery, power-profile, and system-status widget inspired by Serpantinum's visual language. It stays useful on desktop systems with no battery and does not replace Omarchy's notification, session, or power-management services.

## Features

- Battery percentage, charging/discharging/full/charge-limit presentation from Quickshell UPower.
- First-class desktop state: the bar remains visible and the popup offers profiles and system status when no battery exists.
- Power-profile selection through Omarchy's own profile commands.
- Optional system-status grid through Omarchy's own status command.
- Staged popup entrance, smooth battery fill, and a charging pulse that only runs while the popup is open.
- Keyboard-aware Omarchy panel container and normal outside-click/Escape dismissal.
- Five-second refresh only while open; no background subprocess polling.

## Requirements

- Omarchy 4.x with its bundled Quickshell shell and plugin host.
- The standard Omarchy commands `omarchy-powerprofiles-list`, `omarchy-powerprofiles-set`, and `omarchy-system-stats`.
- UPower support supplied through the installed Quickshell build.

There are **no packages to install**. The plugin deliberately reuses what supported Omarchy installations provide. It ships no setup scripts, package-manager hooks, service units, fonts, sounds, or theme generator. Unsupported profile hardware produces an unavailable state without breaking battery or system status.

## Install

Once the repository is published:

```bash
omarchy plugin add https://github.com/Somnius/serpantinum-omarchy-power.git --enable
```

For a local development checkout:

```bash
omarchy plugin validate /path/to/serpantinum-omarchy-power
```

Do not copy files into `/usr/share/omarchy`; that directory is package-owned. Omarchy's plugin manager installs user plugins in the supported user-owned location.

## Settings

Inline widget settings live with the plugin's entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "somnius.serpantinum-power",
  "showPercentage": true,
  "showSystemStats": true,
  "reducedMotion": false
}
```

| Setting | Default | Effect |
|---|---:|---|
| `showPercentage` | `true` | Shows the charge percentage beside the horizontal bar icon when a battery exists. |
| `showSystemStats` | `true` | Shows the system-status section and enables its open-popup refresh. |
| `reducedMotion` | `false` | Disables the entrance, battery-fill, and continuous charging animations. |

Omarchy hot-reloads plugin and shell configuration changes. Use `omarchy bar move somnius.serpantinum-power --section right` to reposition the widget.

## Behavior and failure handling

UPower is authoritative for battery presence, state, and charge. The plugin never guesses a battery on desktops. Profile and system-stat commands start on popup open and repeat every five seconds only while it remains open. Read-only queries are cancelled on close and time out after four seconds. Profile changes are serialized and time out after ten seconds; another click is ignored while one is active. A failed change is reported in the popup, then authoritative state is refreshed only if the popup remains open.

The widget intentionally has no suspend, shutdown, reboot, lock, notification-history, or DND controls. Those capabilities already have Omarchy owners and should not be duplicated inside a decorative status plugin.

## Development

Run the pure model tests and host validation:

```bash
node tests/model.test.js
omarchy plugin validate .
qmllint -I /usr/share/omarchy/shell Panel.qml
```

Test on both a laptop and a no-battery desktop. Exercise AC transitions, missing profile support, shell hot reload, repeated open/close, vertical and horizontal bars, and live theme changes. Verify that no timer-driven process runs after the popup closes.

## Attribution and license

The implementation is clean-room and unofficial. See [NOTICE.md](NOTICE.md) for provenance and upstream credit. Original code in this repository is available under the [MIT License](LICENSE).
