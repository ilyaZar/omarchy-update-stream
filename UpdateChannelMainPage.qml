import QtQuick
import qs.Commons
import qs.Ui
import "UpdateChannelModel.js" as Model

Column {
  id: root

  required property bool checking
  required property color foreground
  required property string fontFamily
  required property string currentChannel
  property string linkKind: "changelog"
  property string selectedChannel: "stable"
  readonly property bool channelChanged: currentChannel !== "unknown"
    && selectedChannel !== currentChannel
  readonly property bool popupOpen: linkDropdown.popupOpen
    || channelDropdown.popupOpen

  signal applyRequested()
  signal refreshRequested()
  signal settingsRequested()
  signal visitRequested()

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
      foreground: root.foreground
      fontFamily: root.fontFamily
      onChanged: function(value) { root.linkKind = value }
    }

    Button {
      id: visitButton
      width: Style.space(86)
      height: linkDropdown.implicitHeight
      text: "Visit 󰏌"
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      focusable: true
      onClicked: root.visitRequested()
    }
  }

  PanelSectionHeader {
    text: "Update channel"
    foreground: root.foreground
    fontFamily: root.fontFamily
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
    foreground: root.foreground
    fontFamily: root.fontFamily
    onChanged: function(value) { root.selectedChannel = value }
  }

  Text {
    width: parent.width
    text: "Current channel: " + root.currentChannel
    color: "#ebcb8b"
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  Button {
    width: parent.width
    text: "Settings"
    foreground: root.foreground
    fontFamily: root.fontFamily
    fontSize: Style.font.bodySmall
    leftAlign: true
    rightPadding: horizontalPadding + Style.space(20)
    bordered: true
    focusable: true
    onClicked: root.settingsRequested()

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

  PanelSeparator { foreground: root.foreground }

  Row {
    width: parent.width
    spacing: Style.space(6)

    Button {
      width: Style.space(86)
      text: "Apply"
      foreground: root.channelChanged
        ? root.foreground
        : Color.muted
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      focusable: true
      enabled: root.channelChanged
      opacity: enabled ? 1 : 0.35
      onClicked: root.applyRequested()
    }

    Button {
      width: parent.width - Style.space(86) - parent.spacing
      text: root.checking
        ? "Checking update info..."
        : "Refresh update info  \uf021"
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      focusable: true
      enabled: !root.checking
      opacity: enabled ? 1 : 0.35
      onClicked: root.refreshRequested()
    }
  }
}
