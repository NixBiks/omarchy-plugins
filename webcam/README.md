# webcam

Bar widget for the on-demand IPU6 webcam bridge on the X1 Carbon.

The camera there is an Intel IPU6 MIPI sensor relayed into `/dev/video50` by
`v4l2-relayd@ipu7`, and that relay has no idle mode: from start to stop it
pushes frames into the loopback at 30fps whether or not anything reads them,
about 10% of a core. The dotfiles repo therefore keeps it stopped unless the
session asks (`machines/x1carbon/README.md` § Webcam), and this widget is the
ask: click to toggle, glyph lit while the relay runs and is paying for it.

Everything it shows comes from `webcam probe`; the click runs `webcam toggle`.
Both are `scripts/.local/bin/webcam` in the dotfiles repo, which also owns the
unit drop-in and the polkit rule that make a passwordless toggle possible.

Glyphs: 󰖠 on · 󱜷 off · 󰀪 the relay is running without having been asked for
(or was asked for and is down) · 󰜗 the `webcam` script is not on PATH.
