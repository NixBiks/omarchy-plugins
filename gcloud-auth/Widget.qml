// gcloud auth — bar widget over the `gcloud-auth-watch` script.
//
// This is UI only. The verdict comes from `gcloud-auth-watch probe`, which reads
// what the systemd timer's last check recorded and when the session started;
// it never calls gcloud, so polling it is free. Sign-in is
// `gcloud-auth-watch login`, the same terminal the expiry toast opens.
//
// The end time is an estimate: session start plus sessionHours. Workspace
// session control does not tell the client when it will cut the session, so the
// length is a setting that must match the admin policy. The session starts at the
// first sign-in after an observed expiry; a sign-in while the credentials still
// work does not move the end. The check verdict always wins over the countdown.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "nixbiks.gcloud-auth"

  // Last successful probe. Empty until the first one lands, which is why every
  // read below tolerates undefined rather than assuming a shape.
  property var state: ({})
  property bool available: true
  property real nowSec: Date.now() / 1000

  function setting(key, fallback, min) {
    var v = settings && settings[key]
    return (typeof v === "number" && v >= min) ? v : fallback
  }
  readonly property int sessionHours: setting("sessionHours", 24, 1)
  readonly property int refreshSec: setting("refreshIntervalSec", 30, 5)

  readonly property string verdict: (state && state.state) ? String(state.state) : ""
  readonly property real startedAt: (state && state.sessionStartedAt > 0) ? state.sessionStartedAt : 0
  readonly property real endsAt: startedAt > 0 ? startedAt + sessionHours * 3600 : 0
  readonly property real secondsLeft: endsAt > 0 ? endsAt - nowSec : -1
  readonly property bool expired: verdict === "expired"
  // Share of the session left, for the bar. Zero once a check failed.
  readonly property real fraction: expired || endsAt <= 0 ? 0
    : Math.max(0, Math.min(1, secondsLeft / (sessionHours * 3600)))
  readonly property bool known: available && verdict !== "" && (expired || endsAt > 0)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    nowSec = Date.now() / 1000
    if (!probeProc.running) probeProc.running = true
  }

  function signIn() {
    if (root.bar) root.bar.run("gcloud-auth-watch login")
  }

  function recheck() {
    if (root.bar) root.bar.run("systemctl --user start --no-block gcloud-auth-watch.service")
    settleTimer.restart()
  }

  function timeLeft(seconds) {
    if (seconds <= 0) return "0m"
    var h = Math.floor(seconds / 3600)
    var m = Math.floor((seconds % 3600) / 60)
    return h > 0 ? h + "h " + m + "m" : m + "m"
  }

  function clock(epoch) {
    return Qt.formatTime(new Date(epoch * 1000), "HH:mm")
  }

  function ago(epoch) {
    var s = Math.max(0, nowSec - epoch)
    return s < 90 ? "just now" : Math.round(s / 60) + " min ago"
  }

  function describe() {
    if (!available)
      return "gcloud-auth-watch not found\nInstall the rig scripts package."
    var lines = []
    if (expired) lines.push("gcloud credentials expired")
    else if (verdict === "ok") lines.push("gcloud credentials work")
    else lines.push("gcloud credentials not checked yet")

    if (startedAt > 0 && !expired && secondsLeft > 0)
      lines.push(timeLeft(secondsLeft) + " left")
    if (startedAt > 0) {
      lines.push("Session started " + Qt.formatDateTime(new Date(startedAt * 1000), "ddd HH:mm")
        + ", ends about " + Qt.formatDateTime(new Date(endsAt * 1000), "ddd HH:mm")
        + " (" + sessionHours + "h session)")
      if (!expired && secondsLeft <= 0)
        lines.push("⚠ Past the estimate and still working: sessionHours is shorter than the real session")
    } else {
      lines.push("Session start unknown: the countdown starts at the first sign-in after an expiry")
    }
    if (state && state.checkedAt > 0) lines.push("Checked " + ago(state.checkedAt))
    if (state && state.snoozedUntil > nowSec)
      lines.push("Toast snoozed until " + clock(state.snoozedUntil))

    lines.push("\nClick to sign in\nRight-click to check now")
    return lines.join("\n")
  }

  Process {
    id: probeProc
    command: ["gcloud-auth-watch", "probe"]
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
    interval: root.refreshSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A check runs gcloud twice, a few seconds in all.
  Timer {
    id: settleTimer
    interval: 6000
    repeat: false
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? -1 : track.long + scaledHorizontalMargin * 2
    fixedHeight: vertical ? track.long + scaledVerticalPadding * 2 : -1
    tooltipText: root.describe()
    onPressed: function (b) {
      if (b === Qt.RightButton) root.recheck()
      else root.signIn()
    }

    // The fill shrinks toward the start edge as the session runs out: left on a
    // horizontal bar, bottom on a vertical one.
    Rectangle {
      id: track
      readonly property real long: Style.spaceReal(18)
      readonly property real thick: Style.spaceReal(5)
      anchors.centerIn: parent
      width: button.vertical ? thick : long
      height: button.vertical ? long : thick
      radius: thick / 2
      color: "transparent"
      border.width: Style.spaceReal(1)
      border.color: button.foreground
      opacity: root.known ? 1 : 0.4

      Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: button.vertical ? parent.width : parent.width * root.fraction
        height: button.vertical ? parent.height * root.fraction : parent.height
        radius: parent.radius
        color: button.foreground
        visible: root.fraction > 0
      }
    }
  }
}
