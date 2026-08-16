import QtQuick
import Quickshell.Io
import "UpdateChannelModel.js" as Model

QtObject {
  id: root

  property bool updateAvailable: false
  property string currentChannel: "unknown"
  property string devBranch: ""
  property string lastCheckMessage: "Not checked yet"
  readonly property bool checking: _availabilityProcess.running
    || _statusProcess.running

  signal availabilityFinished(bool available)

  function _start(process) {
    if (process.running) return false
    process.running = true
    return true
  }

  function refreshChannel() {
    root._start(_channelProcess)
    root._start(_devBranchProcess)
  }

  function refreshAvailability() {
    return root._start(_availabilityProcess)
  }

  function refreshStatus() {
    return root._start(_statusProcess)
  }

  function clearAvailability() {
    root.updateAvailable = false
    root.lastCheckMessage = "Omarchy is up to date"
  }

  property Process _channelProcess: Process {
    command: ["omarchy", "channel", "current"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.currentChannel = Model.normalizeChannel(text)
    }
  }

  property Process _devBranchProcess: Process {
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

  property Process _availabilityProcess: Process {
    command: ["omarchy", "update", "available"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message !== "") root.lastCheckMessage = message
      }
    }
    onExited: function(exitCode) {
      root.updateAvailable = exitCode === 0
      root.availabilityFinished(root.updateAvailable)
    }
  }

  property Process _statusProcess: Process {
    command: ["omarchy", "update", "status"]
    onExited: root.refreshChannel()
  }

  property Timer _availabilityTimer: Timer {
    interval: 21600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshAvailability()
  }
}
