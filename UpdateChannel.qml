import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "UpdateChannelModel.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.ilyazar.update-channel"

  readonly property string defaultPulseColor: "#a77bd8"
  readonly property var pulseColorPresets: [
    { label: "Wispr Flow purple", value: defaultPulseColor },
    { label: "Green", value: "#a3be8c" },
    { label: "Blue", value: "#3b82f6" },
    { label: "Yellow", value: "#ebcb8b" }
  ]
  readonly property string omarchyPath:
    Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
  readonly property bool opened: panelController.open
  readonly property bool shouldShow: !manualHidden
    && (visibilityMode === "always" || updateService.updateAvailable)

  property bool assumeYes: setting("assumeYes", false) === true
  property bool manualHidden: false
  property string pulseColor: Model.normalizeColor(
    setting("pulseColor", defaultPulseColor), defaultPulseColor)
  property string visibilityMode: Model.normalizePersistentVisibility(
    setting("visibilityMode", "updates"))

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

  function runInPresentation(command) {
    if (!root.bar || command === "") return
    root.bar.run("omarchy-launch-floating-terminal-with-presentation "
      + Util.shellQuote(command))
  }

  function refresh() {
    root.manualHidden = false
    updateService.refreshAvailability()
  }

  function clear() {
    updateService.clearAvailability()
    root.manualHidden = root.visibilityMode !== "always"
  }

  function refreshUpdateInfo() {
    root.manualHidden = false
    updateButton.pulse()
    updateService.refreshStatus()
  }

  function runUpdate() {
    root.runInPresentation(Model.updateCommand(root.assumeYes))
  }

  function applyChannel(channel) {
    var command = Model.channelCommand(channel)
    if (command === "" || channel === updateService.currentChannel) return
    updateButton.pulse()
    root.close()
    root.runInPresentation(command)
  }

  function applySettings(nextAssumeYes, nextColor, nextVisibility) {
    var values = Model.normalizeSettings({
      assumeYes: nextAssumeYes,
      pulseColor: nextColor,
      visibilityMode: nextVisibility
    },
      root.visibilityMode,
      root.defaultPulseColor)

    root.assumeYes = values.assumeYes
    root.visibilityMode = values.visibilityMode
    root.pulseColor = values.pulseColor
    root.persistSettings({
      assumeYes: values.assumeYes,
      pulseColor: values.pulseColor,
      visibilityMode: values.visibilityMode
    })
    updateButton.pulse()
    updatePanel.showMain()

    if (values.hideRequested) {
      root.close()
      hideAfterFeedback.restart()
    } else {
      root.manualHidden = false
    }
  }

  function visitPage(channel, content) {
    if (!root.bar) return
    var url = Model.destination(channel, content, updateService.devBranch)
    root.bar.run("omarchy launch browser " + Util.shellQuote(url))
  }

  onOpenedChanged: {
    if (!opened) return
    updatePanel.reset()
    updateService.refreshChannel()
  }

  Component.onCompleted: updateService.refreshChannel()

  PanelController { id: panelController }

  IpcHandler {
    target: "omarchy.system-update"

    function refresh() { root.broadcast("refresh") }
    function clear() { root.broadcast("clear") }
  }

  UpdateChannelService {
    id: updateService
    onAvailabilityFinished: root.manualHidden = false
    onCurrentChannelChanged: {
      updatePanel.selectedChannel = currentChannel === "unknown"
        ? "stable"
        : currentChannel
    }
  }

  Timer {
    id: hideAfterFeedback
    interval: 2100
    onTriggered: root.manualHidden = true
  }

  visible: shouldShow
  implicitWidth: updateButton.implicitWidth
  implicitHeight: updateButton.implicitHeight

  UpdateChannelButton {
    id: updateButton
    anchors.fill: parent
    bar: root.bar
    checking: updateService.checking
    feedbackColor: root.pulseColor
    lastCheckMessage: updateService.lastCheckMessage
    omarchyPath: root.omarchyPath
    visibilityMode: root.visibilityMode
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.runUpdate()
      else if (mouseButton === Qt.RightButton) root.toggle()
    }
  }

  UpdateChannelPanel {
    id: updatePanel
    anchorItem: updateButton.anchorItem
    owner: root
    bar: root.bar
    open: root.opened
    assumeYes: root.assumeYes
    checking: updateService.checking
    currentChannel: updateService.currentChannel
    pulseColor: root.pulseColor
    pulseColorPresets: root.pulseColorPresets
    visibilityMode: root.visibilityMode
    onApplyChannelRequested: function(channel) { root.applyChannel(channel) }
    onApplySettingsRequested: function(assumeYes, color, visibility) {
      root.applySettings(assumeYes, color, visibility)
    }
    onCloseRequested: root.close()
    onRefreshRequested: root.refreshUpdateInfo()
    onSwitchRequested: function(direction) { root.switchPanel(direction) }
    onVisitRequested: function(channel, content) {
      root.visitPage(channel, content)
    }
  }
}
