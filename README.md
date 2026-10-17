# soren.warp — Cloudflare WARP / Cloudflare One Menu Bar Plugin for Omarchy

A [Quickshell](https://quickshell.com/) bar widget for [Omarchy](https://omarchy.org/) that shows your Cloudflare WARP / Cloudflare One connection state and lets you toggle connect/disconnect from the bar.

## Features

- **Hover** the shield icon for a status tooltip
- **Click** to open a panel with a toggle slider
- **Slider** toggles between connect/disconnect instantly
- **Color-changing icon**: green shield when connected, red when disconnected
- **Solid vs outlined shield**: filled when connected, outlined when disconnected
- **Optimistic toggle**: the switch moves immediately on click, before `warp-cli` confirms
- Shows account type, organization, mode, always-on state, and policy lock status

## Prerequisites

- [Cloudflare WARP](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/) client installed and configured (`warp-cli`)
- Omarchy Linux distribution
- `jq` (for the data scripts)

## Installation

```bash
# Clone into your Omarchy plugins directory
git clone https://github.com/<your-username>/soren.warp.git \
  ~/.config/omarchy/plugins/soren.warp

# Enable the plugin on the right side of the bar
omarchy plugin enable soren.warp right

# Restart the shell (or it may hot-reload automatically)
omarchy restart shell
```

## Usage

- **Hover** the shield icon → see connection status tooltip
- **Click** the shield icon → open the panel
- **Click the toggle** in the panel → connect/disconnect WARP
- **R** key → refresh status
- **Esc** / click outside → close the panel

## Configuration

The plugin supports two settings in `shell.json`:

```json
{
  "id": "soren.warp",
  "showLabel": false,          // Show "WARP" text next to the icon
  "pollIntervalSec": 5          // Refresh interval while panel is open
}
```

Set them via:
```bash
omarchy bar set soren.warp showLabel true right
```

## How it works

The plugin uses two helper scripts:

- `bin/warp-data` — runs `warp-cli status`, `warp-cli registration show/organization`, and `warp-cli --json settings list`, assembles a JSON object describing the connection state
- `bin/warp-action` — runs `warp-cli connect` or `warp-cli disconnect`, then re-polls until the status stabilizes

The `WarpService.qml` component polls `warp-data` on a timer (30s when panel closed, configurable when open) and runs `warp-action` for toggles. The `Panel.qml` component provides the bar button (shield icon) and the popup panel (hero, toggle, stats grid).

## License

MIT
