import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "UpdateChannelModel.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.ilyazar.update-channel"

  readonly property color currentChannelColor: "#ebcb8b"
  readonly property string wisprPurpleColor: "#a77bd8"
  readonly property var pulseColorPresets: [
    { label: "Wispr Flow purple", value: wisprPurpleColor },
    { label: "Green", value: "#a3be8c" },
    { label: "Blue", value: "#3b82f6" },
    { label: "Yellow", value: "#ebcb8b" }
  ]
  readonly property color feedbackColor: pulseColor
  readonly property string omarchyPath: {
    var configured = Quickshell.env("OMARCHY_PATH")
    return configured || "/usr/share/omarchy"
  }
  readonly property bool shouldShow: !manualHidden
    && (visibilityMode === "always" || updateAvailable)
  readonly property bool channelChanged: currentChannel !== "unknown"
    && selectedChannel !== currentChannel
  readonly property bool opened: panelController.open

  property bool updateAvailable: false
  property bool assumeYes: setting("assumeYes", false) === true
  property bool manualHidden: false
  property bool checking: false
  property bool settingsPage: false
  property bool customPulseColorVisible: false
  property bool draftAssumeYes: false
  property string draftPulseColor: wisprPurpleColor
  property string draftVisibilityMode: "updates"
  property string pulseColor: Model.normalizeColor(
    setting("pulseColor", wisprPurpleColor), wisprPurpleColor)
  property string visibilityMode: Model.normalizeVisibility(
    setting("visibilityMode", "updates"))
  property string currentChannel: "unknown"
  property string selectedChannel: "stable"
  property string devBranch: ""
  property string linkKind: "changelog"
  property string lastCheckMessage: "Not checked yet"
  property real pulseOpacity: 1
  property real pulseScale: 1

  function open() { panelController.show() }
  function close() { panelController.hide() }
  function toggle() { opened ? close() : open() }
  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(root, direction)
    return false
  }

  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) {
      if (existing !== "id") entry[existing] = root.settings[existing]
    }
    for (var key in values) entry[key] = values[key]

    root.settings = entry
    if (root.bar && root.bar.shell
        && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function pulse() {
    feedbackPulse.stop()
    root.pulseOpacity = 1
    root.pulseScale = 1
    feedbackPulse.start()
  }

  function refreshChannel() {
    if (!channelProcess.running) channelProcess.running = true
    if (!devBranchProcess.running) devBranchProcess.running = true
  }

  function refresh() {
    root.manualHidden = false
    if (availabilityProcess.running) return
    root.checking = true
    availabilityProcess.running = true
  }

  function clear() {
    root.updateAvailable = false
    root.checking = false
    root.lastCheckMessage = "Omarchy is up to date"
    root.manualHidden = root.visibilityMode !== "always"
  }

  function refreshUpdateInfo() {
    root.manualHidden = false
    root.pulse()
    if (!statusProcess.running) {
      root.checking = true
      statusProcess.running = true
    }
  }

  function runUpdate() {
    if (!root.bar) return
    var command = root.assumeYes ? "omarchy update -y" : "omarchy update"
    root.bar.run("omarchy-launch-floating-terminal-with-presentation "
      + Util.shellQuote(command))
  }

  function applyChannel() {
    if (!root.bar || !root.channelChanged) return
    root.pulse()
    root.close()
    root.bar.run("omarchy-launch-floating-terminal-with-presentation "
      + Util.shellQuote("omarchy channel set " + root.selectedChannel))
  }

  function openSettings() {
    root.draftAssumeYes = root.assumeYes
    root.draftPulseColor = root.pulseColor
    root.draftVisibilityMode = root.visibilityMode
    root.customPulseColorVisible = Model.presetForColor(
      root.pulseColor, root.pulseColorPresets, root.wisprPurpleColor)
      === "custom"
    customPulseColorField.text = root.pulseColor
    root.settingsPage = true
  }

  function closeSettings() {
    root.settingsPage = false
    root.draftVisibilityMode = root.visibilityMode
    root.draftAssumeYes = root.assumeYes
    root.draftPulseColor = root.pulseColor
    root.customPulseColorVisible = false
  }

  function applySettings() {
    var mode = Model.normalizeVisibility(root.draftVisibilityMode)
    var persistedMode = mode === "hidden" ? root.visibilityMode : mode
    var color = Model.normalizeColor(
      root.draftPulseColor, root.wisprPurpleColor)

    root.assumeYes = root.draftAssumeYes
    root.visibilityMode = persistedMode
    root.pulseColor = color
    root.persistSettings({
      assumeYes: root.draftAssumeYes,
      pulseColor: color,
      visibilityMode: persistedMode
    })
    root.pulse()
    root.settingsPage = false

    if (mode === "hidden") {
      root.close()
      hideAfterFeedback.restart()
    } else {
      root.manualHidden = false
    }
  }

  function visitSelectedPage() {
    if (!root.bar) return
    var url = Model.destination(
      root.selectedChannel, root.linkKind, root.devBranch)
    root.bar.run("omarchy launch browser " + Util.shellQuote(url))
  }

  onOpenedChanged: {
    if (!opened) return
    root.settingsPage = false
    root.linkKind = "changelog"
    root.refreshChannel()
  }

  Component.onCompleted: root.refreshChannel()

  PanelController { id: panelController }

  IpcHandler {
    target: "omarchy.system-update"

    function refresh() { root.broadcast("refresh") }
    function clear() { root.broadcast("clear") }
  }

  Process {
    id: channelProcess
    command: ["omarchy", "channel", "current"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var channel = Model.normalizeChannel(text)
        root.currentChannel = channel
        root.selectedChannel = channel === "unknown" ? "stable" : channel
      }
    }
  }

  Process {
    id: devBranchProcess
    command: [
      "bash",
      "-lc",
      "if [[ ${OMARCHY_PATH:-/usr/share/omarchy} != /usr/share/omarchy ]]; "
        + "then git -C \"$OMARCHY_PATH\" branch --show-current 2>/dev/null; fi"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.devBranch = String(text || "").trim()
    }
  }

  Process {
    id: availabilityProcess
    command: ["omarchy", "update", "available"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message !== "") root.lastCheckMessage = message
      }
    }
    onExited: function(exitCode) {
      root.checking = false
      root.updateAvailable = exitCode === 0
      if (root.visibilityMode === "always") root.manualHidden = false
    }
  }

  Process {
    id: statusProcess
    command: ["omarchy", "update", "status"]
    onExited: {
      root.checking = false
      root.refreshChannel()
    }
  }

  Timer {
    interval: 21600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: hideAfterFeedback
    interval: 2100
    onTriggered: root.manualHidden = true
  }

  SequentialAnimation {
    id: feedbackPulse
    loops: 3
    onStopped: {
      root.pulseOpacity = 1
      root.pulseScale = 1
    }
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "pulseOpacity"
        from: 0.65
        to: 1
        duration: 650
        easing.type: Easing.InOutSine
      }
      SequentialAnimation {
        NumberAnimation {
          target: root
          property: "pulseScale"
          from: 1
          to: 1.16
          duration: 325
          easing.type: Easing.InOutSine
        }
        NumberAnimation {
          target: root
          property: "pulseScale"
          from: 1.16
          to: 1
          duration: 325
          easing.type: Easing.InOutSine
        }
      }
    }
  }

  visible: shouldShow
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    labelVisible: false
    hasVisualContent: true
    fixedWidth: Style.bar.statusSlot
    tooltipText: root.checking
      ? "Checking Omarchy updates"
      : root.lastCheckMessage
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.runUpdate()
      else if (mouseButton === Qt.RightButton) root.toggle()
    }
  }

  Item {
    anchors.centerIn: button
    width: Style.font.caption + Style.space(4)
    height: width
    opacity: root.pulseOpacity
    scale: root.pulseScale

    Text {
      anchors.centerIn: parent
      visible: root.visibilityMode !== "always"
      text: "\uf021"
      color: feedbackPulse.running
        ? root.feedbackColor
        : button.foreground
      font.family: button.fontFamily
      font.pixelSize: Style.font.caption
      renderType: Text.NativeRendering

      Behavior on color { ColorAnimation { duration: 160 } }
    }

    Image {
      anchors.fill: parent
      visible: root.visibilityMode === "always"
      source: "file://" + root.omarchyPath + "/icon.png"
      fillMode: Image.PreserveAspectFit
      smooth: true
      opacity: feedbackPulse.running ? 0.75 : 1
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: linkDropdown.popupOpen
        || channelDropdown.popupOpen
        || pulseColorDropdown.popupOpen
        || visibilityDropdown.popupOpen
      onCloseRequested: {
        if (root.settingsPage) root.closeSettings()
        else root.close()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(8)

        Column {
          visible: !root.settingsPage
          width: parent.width
          spacing: Style.space(8)

          Row {
            width: parent.width
            spacing: Style.space(6)

            Dropdown {
              id: linkDropdown
              width: parent.width - visitButton.width - parent.spacing
              showLabel: false
              value: root.linkKind
              options: Model.contentOptions(root.selectedChannel)
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              onChanged: function(value) { root.linkKind = value }
            }

            Button {
              id: visitButton
              width: Style.space(86)
              height: linkDropdown.implicitHeight
              text: "Visit 󰏌"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              onClicked: root.visitSelectedPage()
            }
          }

          PanelSectionHeader {
            text: "Update channel"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Dropdown {
            id: channelDropdown
            width: parent.width
            showLabel: false
            value: root.selectedChannel
            options: [
              { value: "stable", label: "Stable" },
              { value: "rc", label: "RC" },
              { value: "edge", label: "Edge" },
              { value: "dev", label: "Dev" }
            ]
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onChanged: function(value) { root.selectedChannel = value }
          }

          Text {
            width: parent.width
            text: "Current channel: " + root.currentChannel
            color: root.currentChannelColor
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            width: parent.width
            text: "Settings"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            fontSize: Style.font.bodySmall
            leftAlign: true
            rightPadding: horizontalPadding + Style.space(20)
            bordered: true
            focusable: true
            onClicked: root.openSettings()

            Text {
              anchors.right: parent.right
              anchors.rightMargin: parent.horizontalPadding
              anchors.verticalCenter: parent.verticalCenter
              text: "󰅂"
              color: parent.foreground
              font.family: parent.fontFamily
              font.pixelSize: parent.iconSize
            }
          }

          PanelSeparator { foreground: root.bar.foreground }

          Row {
            width: parent.width
            spacing: Style.space(6)

            Button {
              width: Style.space(86)
              text: "Apply"
              foreground: root.channelChanged
                ? root.bar.foreground
                : Color.muted
              fontFamily: root.bar.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              enabled: root.channelChanged
              opacity: enabled ? 1 : 0.35
              onClicked: root.applyChannel()
            }

            Button {
              width: parent.width - Style.space(86) - parent.spacing
              text: root.checking
                ? "Checking update info..."
                : "Refresh update info  \uf021"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              enabled: !root.checking
              opacity: enabled ? 1 : 0.35
              onClicked: root.refreshUpdateInfo()
            }
          }
        }

        Column {
          visible: root.settingsPage
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "Update behavior"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Item {
            width: parent.width
            implicitHeight: Math.max(
              assumeYesLabel.implicitHeight,
              assumeYesToggle.implicitHeight)

            Text {
              id: assumeYesLabel
              anchors.left: parent.left
              anchors.right: assumeYesToggle.left
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              text: "Run without confirmation (-y)"
              color: root.draftAssumeYes
                ? root.bar.foreground
                : Color.muted
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }

            ToggleSwitch {
              id: assumeYesToggle
              anchors.right: parent.right
              anchors.verticalCenter: assumeYesLabel.verticalCenter
              trackHeight: Math.round(
                assumeYesLabel.font.pixelSize * 1.2)
              cursorPad: Style.space(3)
              checked: root.draftAssumeYes
              foreground: root.bar.foreground
              onToggled: root.draftAssumeYes = !checked
            }
          }

          PanelSeparator { foreground: root.bar.foreground }

          Item {
            width: parent.width
            implicitHeight: pulseColorHeader.implicitHeight

            PanelSectionHeader {
              id: pulseColorHeader
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Pulse color"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Rectangle {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(16)
              height: width
              radius: width / 2
              color: Model.normalizeColor(
                root.draftPulseColor, root.wisprPurpleColor)
              border.width: 1
              border.color: Qt.darker(root.bar.foreground, 1.4)
            }
          }

          Dropdown {
            id: pulseColorDropdown
            width: parent.width
            showLabel: false
            value: root.customPulseColorVisible
              ? "custom"
              : Model.presetForColor(root.draftPulseColor,
                root.pulseColorPresets, root.wisprPurpleColor)
            options: root.pulseColorPresets.concat([
              { label: "Custom color", value: "custom" }
            ])
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onChanged: function(value) {
              if (value === "custom") {
                root.customPulseColorVisible = true
                customPulseColorField.text = root.draftPulseColor
                Qt.callLater(function() {
                  customPulseColorField.selectAll()
                  customPulseColorField.forceActiveFocus()
                })
              } else {
                root.customPulseColorVisible = false
                root.draftPulseColor = value
              }
            }
          }

          TextField {
            id: customPulseColorField
            visible: root.customPulseColorVisible
            width: parent.width
            placeholderText: "#RRGGBB"
            foreground: root.bar.foreground
            font.family: root.bar.fontFamily
            validator: RegularExpressionValidator {
              regularExpression: /^#[0-9a-fA-F]{6}$/
            }
            onTextChanged: {
              if (acceptableInput) root.draftPulseColor = text.toLowerCase()
            }
          }

          Text {
            visible: root.customPulseColorVisible
              && customPulseColorField.text !== ""
              && !customPulseColorField.acceptableInput
            width: parent.width
            text: "Use #RRGGBB, for example #a77bd8."
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          PanelSeparator { foreground: root.bar.foreground }

          PanelSectionHeader {
            text: "Icon visibility"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Dropdown {
            id: visibilityDropdown
            width: parent.width
            showLabel: false
            value: root.draftVisibilityMode
            options: [
              {
                value: "updates",
                label: "Show only when updates exist"
              },
              {
                value: "hidden",
                label: "Hide until next availability check"
              },
              {
                value: "always",
                label: "Always show with Omarchy logo"
              }
            ]
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onChanged: function(value) {
              root.draftVisibilityMode = value
            }
          }

          Text {
            width: parent.width
            text: root.draftVisibilityMode === "hidden"
              ? "The next manual or six-hour check may reveal the icon."
              : (root.draftVisibilityMode === "always"
                ? "The Omarchy logo replaces the refresh glyph."
                : "The icon follows update availability.")
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          PanelSeparator { foreground: root.bar.foreground }

          Row {
            width: parent.width
            spacing: Style.space(6)

            Button {
              width: Style.space(86)
              text: "Back"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              onClicked: root.closeSettings()
            }

            Button {
              width: parent.width - Style.space(86) - parent.spacing
              text: "Apply"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              enabled: !root.customPulseColorVisible
                || customPulseColorField.acceptableInput
              opacity: enabled ? 1 : 0.35
              onClicked: root.applySettings()
            }
          }
        }
      }
    }
  }
}
