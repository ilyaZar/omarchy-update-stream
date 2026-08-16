import QtQuick
import qs.Commons
import qs.Ui
import "UpdateChannelModel.js" as Model

Column {
  id: root

  required property bool assumeYes
  required property color foreground
  required property string fontFamily
  required property string pulseColor
  required property var pulseColorPresets
  required property string visibilityMode

  property bool _customPulseColorVisible: false
  property bool _draftAssumeYes: false
  property string _draftPulseColor: "#a77bd8"
  property string _draftVisibilityMode: "updates"
  readonly property bool popupOpen: pulseColorDropdown.popupOpen
    || visibilityDropdown.popupOpen

  signal applyRequested(
    bool assumeYes,
    string color,
    string visibility)
  signal backRequested()

  function reset() {
    root._draftAssumeYes = root.assumeYes
    root._draftPulseColor = root.pulseColor
    root._draftVisibilityMode = root.visibilityMode
    root._customPulseColorVisible = Model.presetForColor(
      root.pulseColor, root.pulseColorPresets, "#a77bd8") === "custom"
    customPulseColorField.text = root.pulseColor
  }

  spacing: Style.space(8)

  PanelSectionHeader {
    text: "Update behavior"
    foreground: root.foreground
    fontFamily: root.fontFamily
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
      color: root._draftAssumeYes ? root.foreground : Color.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    ToggleSwitch {
      id: assumeYesToggle
      anchors.right: parent.right
      anchors.verticalCenter: assumeYesLabel.verticalCenter
      trackHeight: Math.round(assumeYesLabel.font.pixelSize * 1.2)
      cursorPad: Style.space(3)
      checked: root._draftAssumeYes
      foreground: root.foreground
      onToggled: root._draftAssumeYes = !checked
    }
  }

  PanelSeparator { foreground: root.foreground }

  Item {
    width: parent.width
    implicitHeight: pulseColorHeader.implicitHeight

    PanelSectionHeader {
      id: pulseColorHeader
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Pulse color"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Rectangle {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(16)
      height: width
      radius: width / 2
      color: Model.normalizeColor(root._draftPulseColor, "#a77bd8")
      border.width: 1
      border.color: Qt.darker(root.foreground, 1.4)
    }
  }

  Dropdown {
    id: pulseColorDropdown
    width: parent.width
    showLabel: false
    value: root._customPulseColorVisible
      ? "custom"
      : Model.presetForColor(
        root._draftPulseColor, root.pulseColorPresets, "#a77bd8")
    options: root.pulseColorPresets.concat([
      { label: "Custom color", value: "custom" }
    ])
    foreground: root.foreground
    fontFamily: root.fontFamily
    onChanged: function(value) {
      if (value === "custom") {
        root._customPulseColorVisible = true
        customPulseColorField.text = root._draftPulseColor
        Qt.callLater(function() {
          customPulseColorField.selectAll()
          customPulseColorField.forceActiveFocus()
        })
      } else {
        root._customPulseColorVisible = false
        root._draftPulseColor = value
      }
    }
  }

  TextField {
    id: customPulseColorField
    visible: root._customPulseColorVisible
    width: parent.width
    placeholderText: "#RRGGBB"
    foreground: root.foreground
    font.family: root.fontFamily
    validator: RegularExpressionValidator {
      regularExpression: /^#[0-9a-fA-F]{6}$/
    }
    onTextChanged: {
      if (acceptableInput) root._draftPulseColor = text.toLowerCase()
    }
  }

  Text {
    visible: root._customPulseColorVisible
      && customPulseColorField.text !== ""
      && !customPulseColorField.acceptableInput
    width: parent.width
    text: "Use #RRGGBB, for example #a77bd8."
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  PanelSeparator { foreground: root.foreground }

  PanelSectionHeader {
    text: "Icon visibility"
    foreground: root.foreground
    fontFamily: root.fontFamily
  }

  Dropdown {
    id: visibilityDropdown
    width: parent.width
    showLabel: false
    value: root._draftVisibilityMode
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
    foreground: root.foreground
    fontFamily: root.fontFamily
    onChanged: function(value) { root._draftVisibilityMode = value }
  }

  Text {
    width: parent.width
    text: root._draftVisibilityMode === "hidden"
      ? "The next manual or six-hour check may reveal the icon."
      : (root._draftVisibilityMode === "always"
        ? "The Omarchy logo replaces the refresh glyph."
        : "The icon follows update availability.")
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  PanelSeparator { foreground: root.foreground }

  Row {
    width: parent.width
    spacing: Style.space(6)

    Button {
      width: Style.space(86)
      text: "Back"
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      focusable: true
      onClicked: root.backRequested()
    }

    Button {
      width: parent.width - Style.space(86) - parent.spacing
      text: "Apply"
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      focusable: true
      enabled: !root._customPulseColorVisible
        || customPulseColorField.acceptableInput
      opacity: enabled ? 1 : 0.35
      onClicked: root.applyRequested(
        root._draftAssumeYes,
        root._draftPulseColor,
        root._draftVisibilityMode)
    }
  }
}
