// Server Mode — bar widget over the `server-mode` script.
//
// This is UI only. Every fact comes from `server-mode probe` and the toggle is
// `server-mode toggle`; nothing about virtual outputs, Sunshine or the clamshell
// is decided here. That split is deliberate — the mechanism lives beside its
// contract test in the dotfiles repo, and duplicating any of it in QML would
// make this a second opinion about state the script already owns.
//
// It replaces a `type: "command"` bar module that could only ever render one
// glyph and one tooltip line. The reason it is worth more than that is `warn`:
// in server mode with the lid shut and no DRM-connected external, Omarchy's
// clamshell never fires, so the internal panel stays lit with idle DPMS
// suppressed — a burn-in risk on an OLED that nothing else surfaces.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "nixbiks.server-mode"

  // Last successful probe. Empty until the first one lands, which is why every
  // read below tolerates undefined rather than assuming a shape.
  property var state: ({})
  property bool available: true

  readonly property bool server: state && state.mode === "server"
  readonly property string warning: (state && state.warn) ? String(state.warn) : ""

  readonly property int refreshSec: {
    var v = settings && settings.refreshIntervalSec
    return (typeof v === "number" && v >= 1) ? v : 5
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!probeProc.running) probeProc.running = true
  }

  function toggle() {
    if (root.bar) root.bar.run("server-mode toggle")
    // The script does its work synchronously but the compositor needs a moment
    // to create or drop the virtual output; re-read once that has settled.
    settleTimer.restart()
  }

  function describe() {
    if (!available)
      return "server-mode not found\nInstall the dotfiles scripts package."
    if (!state || !state.mode)
      return "Server mode\nReading…"

    var lines = []
    lines.push(server
      ? "Server mode — lid shut, nothing suspends"
      : "Normal laptop — lid close suspends")

    lines.push("Virtual output: " + (state.output ? state.output : "none"))

    var sun = state.sunshine || {}
    if (sun.active)
      lines.push("Sunshine: streaming " + (sun.pinned || "?")
        + (sun.pinMatches ? "" : "  ⚠ pinned to an output that is not live"))
    else
      lines.push("Sunshine: stopped" + (sun.pinned ? " (pinned " + sun.pinned + ")" : ""))

    if (state.internal)
      lines.push("Internal panel: " + state.internal.name + " "
        + (state.internal.disabled ? "dark" : "LIT"))

    lines.push("Lid " + (state.lid || "?")
      + ", external display " + (state.drmExternal ? "connected" : "none"))

    if (warning === "panel-lit-behind-shut-lid")
      lines.push("\n⚠ The panel is lit behind a shut lid with idle blanking off.\n"
        + "No DRM external means Omarchy's clamshell never fires.\n"
        + "Attach a display or a dummy plug, or leave server mode.")

    lines.push("\nClick to " + (server ? "go back to an ordinary laptop" : "start server mode"))
    return lines.join("\n")
  }

  Process {
    id: probeProc
    command: ["server-mode", "probe"]
    stdout: StdioCollector { id: probeOut; waitForEnd: true }
    onExited: function (exitCode) {
      if (exitCode !== 0) {
        // Exit 127 is "no such command"; anything else is a live script that
        // could not answer, which should not be reported as "not installed".
        root.available = (exitCode !== 127)
        return
      }
      root.available = true
      try {
        root.state = JSON.parse(String(probeOut.text || "")) || ({})
      } catch (e) {
        root.state = ({})
      }
    }
  }

  Timer {
    id: pollTimer
    interval: root.refreshSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: settleTimer
    interval: 1200
    repeat: false
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Same glyphs the script's own status output uses, so the bar looks
    // identical to the command module it replaces except when warning.
    text: !root.available ? "󰜗"
        : root.warning !== "" ? "󰀪"
        : root.server ? "󰒋"
        : "󰌢"
    // `active` is what Bar.qml's command module derived from class === "active";
    // keeping it means the lit/dim behaviour carries over unchanged.
    active: root.server
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: root.describe()
    onPressed: root.toggle()
  }
}
