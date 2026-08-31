# Server Mode

Bar widget for `server-mode`, the switch that turns a laptop into an always-on
office box: Hyprland virtual output + Sunshine + `no-sleep`, and back again.

The widget is **UI only**. Every fact comes from `server-mode probe` and the
toggle is `server-mode toggle`. Nothing about virtual outputs, Sunshine or the
clamshell is decided in QML — that mechanism lives in the dotfiles repo next to
the contract test that pins it, and a second opinion here would be a bug waiting
to happen.

## Requires

`server-mode` on `PATH`, from [NixBiks/rig](https://github.com/NixBiks/rig)
(`scripts/.local/bin/server-mode`). Without it the widget shows a disconnected
glyph and says so rather than disappearing.

## What it shows

Click toggles. The tooltip carries what the old one-line bar module could not:

- mode, and the virtual output's actual name (`HEADLESS-n` is assigned, not chosen)
- whether Sunshine is streaming, and whether its pinned output is the live one
- the internal panel: **dark** or **LIT**
- lid state and whether a DRM-connected external is attached

## The warning is the point

In server mode, with the lid shut and no DRM-connected external, Omarchy's
clamshell never disables the internal panel — its gate is
`omarchy-hw-external-monitors`, which reads `/sys/class/drm`, and a virtual
output has no DRM node. Combined with `no-sleep` suppressing idle blanking, the
panel stays lit behind a closed lid indefinitely. On an OLED that is a burn-in
risk.

`server-mode` documents this as an open defect and deliberately does not paper
over it. The widget's job is to make it *visible*: the glyph changes and the
tooltip says which display to attach. That is the reason this exists as a plugin
rather than a `type: "command"` module, which can only render one glyph and one
tooltip line.

## Settings

`refreshIntervalSec` (default 5) — how often `server-mode probe` runs.
