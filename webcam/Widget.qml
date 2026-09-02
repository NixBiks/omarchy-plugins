// Webcam — bar widget over the `webcam` script.
//
// This is UI only. Every fact comes from `webcam probe` and the toggle is
// `webcam toggle`; what "on" means — the runtime flag, the system unit, the
// polkit rule that lets a session drive it — is decided in the dotfiles repo
// beside the unit drop-in, not here. Same split as nixbiks.server-mode, for the
// same reason: a second opinion about state the script already owns would only
// ever disagree with it.
//
// Why a glyph for something the menu can also toggle: the relay costs ~10% of
// a core from the moment it starts, reader or not, and nothing else on screen
// says the camera is up. Lit means paying for it. The warning state is the
// relay running without anyone having asked — the package's boot start or
// post-resume start slipping past the on-demand condition.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "nixbiks.webcam"

  // Last successful probe. Empty until the first one lands, which is why every
  // read below tolerates undefined rather than assuming a shape.
  property var state: ({})
  property bool available: true

  readonly property bool on: state && state.on === true
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
    if (root.bar) root.bar.run("webcam toggle")
    // `systemctl start` blocks until the unit is up, and the package's
    // ExecStartPost sleeps 2s before restarting wireplumber; re-read once that
    // has had time to finish rather than showing the old state until the next
    // poll.
    settleTimer.restart()
  }

  function describe() {
    if (!available)
      return "webcam not found\nInstall the dotfiles scripts package."
    if (!state || typeof state.on !== "boolean")
      return "Webcam\nReading…"

    var node = state.node ? String(state.node) : "/dev/video50"
    var lines = []
    lines.push(on
      ? "Webcam on — bridging the IPU6 sensor to " + node + " (~10% of a core, reader or not)"
      : "Webcam off — relay stopped, apps see no camera")

    lines.push("Unit: " + (state.unit || "?") + (state.armed ? ", comes back after suspend" : ""))

    if (state.nodePresent === false)
      lines.push("⚠ " + node + " is missing — camera-init has not loaded v4l2loopback")

    if (warning === "running-unasked")
      lines.push("\n⚠ The relay is running but nothing asked for it.\n"
        + "Turn it off here, or see who started it: systemctl status v4l2-relayd@ipu7")
    else if (warning === "asked-but-down")
      lines.push("\n⚠ The camera was turned on but the relay is not running.\n"
        + "Check: systemctl status v4l2-relayd@ipu7")

    lines.push("\nClick to turn the webcam " + (on ? "off" : "on"))
    return lines.join("\n")
  }

  Process {
    id: probeProc
    command: ["webcam", "probe"]
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
    interval: 3500
    repeat: false
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Same glyphs the script's own status output uses (nf-md-webcam and
    // nf-md-webcam_off), so the menu row and the bar agree.
    text: !root.available ? "󰜗"
        : root.warning !== "" ? "󰀪"
        : root.on ? "󰖠"
        : "󱜷"
    active: root.on
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: root.describe()
    onPressed: root.toggle()
  }
}
