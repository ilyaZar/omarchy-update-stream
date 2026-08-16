import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var bar
  required property bool checking
  required property color feedbackColor
  required property string lastCheckMessage
  required property string omarchyPath
  required property string visibilityMode
  readonly property var anchorItem: button

  signal pressed(int mouseButton)

  function pulse() {
    feedbackPulse.stop()
    content.opacity = 1
    content.scale = 1
    feedbackPulse.start()
  }

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
    onPressed: function(mouseButton) { root.pressed(mouseButton) }
  }

  Item {
    id: content
    anchors.centerIn: button
    width: Style.font.caption + Style.space(4)
    height: width

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

  SequentialAnimation {
    id: feedbackPulse
    loops: 3
    onStopped: {
      content.opacity = 1
      content.scale = 1
    }
    ParallelAnimation {
      NumberAnimation {
        target: content
        property: "opacity"
        from: 0.65
        to: 1
        duration: 650
        easing.type: Easing.InOutSine
      }
      SequentialAnimation {
        NumberAnimation {
          target: content
          property: "scale"
          from: 1
          to: 1.16
          duration: 325
          easing.type: Easing.InOutSine
        }
        NumberAnimation {
          target: content
          property: "scale"
          from: 1.16
          to: 1
          duration: 325
          easing.type: Easing.InOutSine
        }
      }
    }
  }
}
