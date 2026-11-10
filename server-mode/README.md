# Server Mode

Bar widget for `server-mode`, the switch that turns a laptop into an always-on
office box: a Hyprland virtual output that gliff mirrors, plus `no-sleep`, and
back again.

The widget is UI only. Every fact comes from `server-mode probe`, and the toggle
is `server-mode toggle`. QML decides nothing about virtual outputs, gliff or the
clamshell. That mechanism lives in the dotfiles repo, next to the contract test
that pins it. A second opinion here is a bug waiting to happen.

## Requires

`server-mode` on `PATH`, from [NixBiks/rig](https://github.com/NixBiks/rig)
(`scripts/.local/bin/server-mode`). Without it the widget shows a disconnected
glyph and says so rather than disappearing.

## What it shows

Click toggles. The tooltip carries what the old one-line bar module did not:

- mode, and the virtual output's actual name (`HEADLESS-n` is assigned, not chosen)
- whether a gliff session is connected. `server-mode off` refuses while one is,
  so the tooltip says so before you click.
- the internal panel: dark or LIT
- lid state and whether a DRM-connected external is attached

## The warning is the point

In server mode, the lid can be shut with no DRM-connected external. Omarchy's
clamshell then never disables the internal panel. Its gate is
`omarchy-hw-external-monitors`, which reads `/sys/class/drm`, and a virtual
output has no DRM node. `no-sleep` also stops idle blanking, so the panel stays
lit behind a closed lid. On an OLED that is a burn-in risk.

`server-mode`'s panel guard switches the panel off within 30 seconds. The
widget's job is to make a guard that stopped working visible: the glyph
changes, and the tooltip names the guard's unit to look at. That is the reason
this exists as a plugin rather than a `type: "command"` module, which can only
render one glyph and one tooltip line.

## Settings

`refreshIntervalSec` (default 5): how often `server-mode probe` runs.
