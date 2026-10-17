import QtQuick
import Quickshell
import Quickshell.Io

// Runs the plugin's bin/ helpers and exposes their JSON as reactive state.
// A poll process on a timer keeps the bar icon fresh; a separate action
// process handles connect/disconnect toggles and re-reads state afterwards.
//
// Optimistic toggle: _desired is -1 when we follow the real status, or
// 0/1 while a connect/disconnect is still in flight. `connected` reads
// _desired first so the bar icon and panel slider flip instantly on click,
// without waiting for warp-cli to confirm the change.
Item {
  id: root

  property string binDir: ""
  property int pollInterval: 5000
  property bool live: false       // true while the panel is open

  // Optimistic state: -1 = follow real status, 0 = turning off, 1 = turning on
  property int _desired: -1

  property var snapshot: ({
    status: "Disconnected",
    reason: "",
    account: "Unknown",
    organization: "",
    mode: "",
    alwaysOn: false,
    switchLocked: false,
    canToggle: false,
    error: null
  })

  readonly property string status:     snapshot.status
  readonly property string reason:     snapshot.reason
  readonly property string account:    snapshot.account
  readonly property string organization: snapshot.organization
  readonly property string mode:       snapshot.mode
  readonly property bool alwaysOn:     snapshot.alwaysOn
  readonly property bool switchLocked: snapshot.switchLocked
  readonly property bool canToggle:    snapshot.canToggle
  readonly property string error:      snapshot.error

  // The real connection state from the last status poll.
  readonly property bool trulyConnected: snapshot.status === "Connected"

  // Optimistic connected state: reflects a pending toggle immediately.
  readonly property bool connected: _desired === -1 ? trulyConnected : (_desired === 1)

  readonly property bool busy: actionProc.running

  signal updated()

  function _ingest(text) {
    var parsed
    try { parsed = JSON.parse(String(text || "").trim()) } catch (e) { return }
    if (!parsed || !parsed.status) return

    // Reality has caught up with any pending optimistic toggle — clear it
    // so the icon reverts to following the real status.
    if (root._desired !== -1 && parsed.status === (root._desired === 1 ? "Connected" : "Disconnected")) {
      root._desired = -1
    }

    root.snapshot = parsed
    root.updated()
  }

  function refresh() {
    if (pollProc.running) return
    pollProc.command = [root.binDir + "/warp-data"]
    pollProc.running = true
  }

  function act(verb) {
    if (actionProc.running) return
    var wasConnected = root.connected
    // Set optimistic state immediately so the UI reacts before warp-cli finishes.
    if (verb === "connect") root._desired = 1
    else if (verb === "disconnect") root._desired = 0
    actionProc.command = [root.binDir + "/warp-action", String(verb || "refresh")]
    actionProc.running = true
  }

  Process {
    id: pollProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root._ingest(text) }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root._ingest(text) }
  }

  // Fast poll while the panel is open; slow otherwise so the bar icon stays
  // current without meaningful CPU cost.
  Timer {
    interval: root.live ? Math.max(2000, root.pollInterval) : 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
