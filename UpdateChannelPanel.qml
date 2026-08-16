import QtQuick
import qs.Commons
import qs.Ui

KeyboardPanel {
  id: root

  required property bool assumeYes
  required property bool checking
  required property string currentChannel
  required property string pulseColor
  required property var pulseColorPresets
  required property string visibilityMode
  property alias selectedChannel: mainPage.selectedChannel
  readonly property bool channelChanged: mainPage.channelChanged
  property bool _settingsPage: false

  signal applyChannelRequested(string channel)
  signal applySettingsRequested(
    bool assumeYes,
    string color,
    string visibility)
  signal closeRequested()
  signal refreshRequested()
  signal switchRequested(int direction)
  signal visitRequested(string channel, string content)

  function showMain() {
    root._settingsPage = false
  }

  function _showSettings() {
    settingsPageContent.reset()
    root._settingsPage = true
  }

  function reset() {
    mainPage.linkKind = "changelog"
    root.showMain()
  }

  focusTarget: keyCatcher
  contentWidth: fittedContentWidth(Style.space(340))
  contentHeight: fittedContentHeight(panelColumn.implicitHeight)

  PanelKeyCatcher {
    id: keyCatcher
    anchors.fill: parent
    blocked: mainPage.popupOpen || settingsPageContent.popupOpen
    onCloseRequested: {
      if (root._settingsPage) root.showMain()
      else root.closeRequested()
    }
    onTabRequested: function(direction) { root.switchRequested(direction) }

    Column {
      id: panelColumn
      width: parent.width
      spacing: Style.space(8)

      UpdateChannelMainPage {
        id: mainPage
        visible: !root._settingsPage
        width: parent.width
        checking: root.checking
        currentChannel: root.currentChannel
        fontFamily: root.bar.fontFamily
        foreground: root.bar.foreground
        onApplyRequested: root.applyChannelRequested(selectedChannel)
        onRefreshRequested: root.refreshRequested()
        onSettingsRequested: root._showSettings()
        onVisitRequested: root.visitRequested(selectedChannel, linkKind)
      }

      UpdateChannelSettingsPage {
        id: settingsPageContent
        visible: root._settingsPage
        width: parent.width
        assumeYes: root.assumeYes
        fontFamily: root.bar.fontFamily
        foreground: root.bar.foreground
        pulseColor: root.pulseColor
        pulseColorPresets: root.pulseColorPresets
        visibilityMode: root.visibilityMode
        onApplyRequested: function(assumeYes, color, visibility) {
          root.applySettingsRequested(assumeYes, color, visibility)
        }
        onBackRequested: root.showMain()
      }
    }
  }
}
