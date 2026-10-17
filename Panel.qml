import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "soren.warp"
  ipcTarget: moduleName
  manageIpc: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleConnection() {
    if (!root.canToggle || service.busy) return
    service.act(root.connected ? "disconnect" : "connect")
  }

  // Use the service's optimistic connected state so the bar icon and
  // toggle flip instantly on click, before warp-cli confirms the change.
  readonly property bool connected: service.connected
  readonly property bool canToggle: service.canToggle && !service.switchLocked
  readonly property color fg: bar ? bar.foreground : Color.foreground

  onOpenedChanged: {
    service.live = opened
    if (opened) {
      service.refresh()
      flick.contentY = 0
    }
  }

  WarpService {
    id: service
    binDir: String(Qt.resolvedUrl("bin")).replace(/^file:\/\//, "")
    pollInterval: Math.max(2000, Math.min(60000,
      (Number(root.setting("pollIntervalSec", 5)) || 5) * 1000))
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { service.refresh(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: service.busy ? Model.iconForStatus("SwitchingModes") : Model.iconForStatus(service.status)
    foreground: root.connected ? "#23d18b" : "#f85149"
    opacity: service.busy ? 0.6 : 1
    tooltipText: root.connected
      ? ("WARP connected  ·  " + Model.reasonLabel(service.reason) + (service.organization ? "  ·  " + service.organization : ""))
      : ("WARP disconnected" + (service.switchLocked ? "  ·  locked by policy" : ""))
    onPressed: function(btn) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340), Style.space(400))
    contentHeight: Math.max(Style.space(200), Math.round(Math.min(
      availableCardHeight,
      Style.space(520),
      contentColumn.implicitHeight + verticalContentInset)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t === "r" || t === "R") service.refresh() }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
          id: contentColumn
          width: flick.width
          spacing: Style.space(14)

          PanelSeparator { foreground: root.fg }

          PanelHero {
            width: parent.width
            title: Model.statusLabel(service.status)
            meta: service.busy
              ? (root.connected ? "Connecting…" : "Disconnecting…")
              : (root.connected ? "Network healthy" : "Disconnected")
            foreground: root.fg
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: service.busy ? Model.iconForStatus("SwitchingModes") : Model.iconForStatus(service.status)
                color: root.connected ? "#23d18b" : (Model.isTerminalError(service.error) ? Color.urgent : Qt.darker(root.fg, 1.5))
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          Toggle {
            width: parent.width
            label: root.connected ? "Disconnect WARP" : "Connect WARP"
            description: root.connected
              ? (service.organization ? service.organization : "Tunnel active")
              : (Model.reasonLabel(service.reason) || "Tunnel is down")
            checked: root.connected
            foreground: root.fg
            accent: root.connected ? "#23d18b" : "#f85149"
            fontFamily: root.fontFamily
            onClicked: { if (root.canToggle) root.toggleConnection() }
          }

          // ---------- Locked by policy ----------
          BorderSurface {
            visible: service.switchLocked
            width: parent.width
            implicitHeight: Style.space(48)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04)
            borderSpec: Border.flat(Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12), Style.normalBorderWidth)
            radius: Style.cornerRadius

            Column {
              anchors.fill: parent
              anchors.margins: Style.space(12)
              spacing: Style.space(4)

              Text {
                width: parent.width
                text: "Connection locked by policy"
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }
              Text {
                width: parent.width
                text: "Your organization's WARP policy disables switching."
                color: Qt.darker(root.fg, 1.5)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }

          // ---------- Service unavailable / error ----------
          BorderSurface {
            visible: service.status === "Disconnected" && service.error === "service"
            width: parent.width
            implicitHeight: Style.space(48)
            color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.08)
            borderSpec: Border.flat(Color.urgent, Style.normalBorderWidth)
            radius: Style.cornerRadius

            Column {
              anchors.fill: parent
              anchors.margins: Style.space(12)
              spacing: Style.space(6)

              Text {
                width: parent.width
                text: "WARP service is not available"
                color: Color.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }
              Text {
                width: parent.width
                text: "Check that warp-svc is running and that warp-cli can reach it."
                color: Qt.darker(root.fg, 1.5)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              Button {
                text: "Retry"
                bordered: true
                focusable: true
                foreground: Color.urgent
                fontFamily: root.fontFamily
                onClicked: service.refresh()
              }
            }
          }
          Grid {
            id: statsGrid
            width: parent.width
            columns: 2
            columnSpacing: Style.space(16)
            rowSpacing: Style.spacing.sm

            StatPair { label: "Account"; value: Model.accountLabel(service.account) }
            StatPair { label: "Organization"; value: service.organization || "—" }
            StatPair { label: "Mode"; value: Model.modeLabel(service.mode) }
            StatPair {
              label: "Status"
              value: Model.statusLabel(service.status)
              valueColor: Model.colorForStatus(service.status, { ok: "#23d18b", bad: Color.urgent, warn: Qt.darker(root.fg, 1.5) })
              useValueColor: true
            }
            StatPair { label: "Always On"; value: service.alwaysOn ? "On" : "Off" }
            StatPair { label: "Policy locked"; value: service.switchLocked ? "Yes" : "No" }
          }

          Text {
            width: parent.width
            text: "R refresh  ·  Esc close"
            color: Qt.darker(root.fg, 1.5)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }

  component StatPair: Item {
    id: sp
    property string label: ""
    property string value: ""
    property color valueColor: "transparent"
    property bool useValueColor: false
    width: (statsGrid.width - statsGrid.columnSpacing) / 2
    implicitHeight: Math.max(spLabel.implicitHeight, spValue.implicitHeight)

    Text {
      id: spLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: sp.label + ":"
      color: Qt.darker(root.fg, 1.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
    Text {
      id: spValue
      anchors.right: parent.right
      anchors.left: spLabel.right
      anchors.leftMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      text: sp.value
      color: sp.useValueColor ? sp.valueColor : root.fg
      elide: Text.ElideRight
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      horizontalAlignment: Text.AlignRight
    }
  }
}
