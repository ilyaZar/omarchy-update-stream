#!/bin/bash

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$PLUGIN_DIR/manifest.json"
QML="$PLUGIN_DIR/UpdateChannel.qml"
BUTTON="$PLUGIN_DIR/UpdateChannelButton.qml"
MAIN_PAGE="$PLUGIN_DIR/UpdateChannelMainPage.qml"
MODEL="$PLUGIN_DIR/UpdateChannelModel.js"
PANEL="$PLUGIN_DIR/UpdateChannelPanel.qml"
SERVICE="$PLUGIN_DIR/UpdateChannelService.qml"
SETTINGS_PAGE="$PLUGIN_DIR/UpdateChannelSettingsPage.qml"

fail() {
  echo "[error] $1" >&2
  exit 1
}

expect_text() {
  local file="$1"
  local text="$2"
  rg -Fq "$text" "$file" || fail "missing '$text' in ${file#$PLUGIN_DIR/}"
}

jq -e '
  .schemaVersion == 1
  and .id == "io.github.ilyazar.update-channel"
  and .kinds == ["bar-widget"]
  and .entryPoints.barWidget == "UpdateChannel.qml"
  and .omarchy.clonedFrom == "omarchy.system-update"
' "$MANIFEST" >/dev/null || fail "manifest contract failed"

expect_text "$QML" 'target: "omarchy.system-update"'
expect_text "$QML" 'import Quickshell.Io'
expect_text "$QML" 'import qs.Ui'
expect_text "$QML" 'if (mouseButton === Qt.LeftButton) root.runUpdate()'
expect_text "$QML" 'else if (mouseButton === Qt.RightButton) root.toggle()'
expect_text "$QML" 'label: "Wispr Flow purple"'
expect_text "$QML" 'root.visibilityMode = values.visibilityMode'
expect_text "$QML" 'root.pulseColor = values.pulseColor'

expect_text "$BUTTON" 'source: "file://" + root.omarchyPath + "/icon.png"'
expect_text "$BUTTON" 'signal pressed(int mouseButton)'
expect_text "$MAIN_PAGE" '&& selectedChannel !== currentChannel'
expect_text "$MAIN_PAGE" 'color: "#ebcb8b"'
expect_text "$PANEL" 'mainPage.linkKind = "changelog"'
expect_text "$PANEL" 'signal applyChannelRequested(string channel)'
expect_text "$SERVICE" '["omarchy", "update", "status"]'
expect_text "$SERVICE" 'readonly property bool checking:'
expect_text "$SETTINGS_PAGE" 'label: "Always show with Omarchy logo"'
expect_text "$SETTINGS_PAGE" 'text: "Pulse color"'

expect_text "$MODEL" 'return assumeYes === true ? "omarchy update -y"'
expect_text "$MODEL" '"omarchy channel set " + normalized'
expect_text "$MODEL" 'function normalizeColor(value, fallback)'
expect_text "$MODEL" 'function normalizeSettings('
expect_text "$MODEL" 'return repositoryUrl + "/releases/latest"'
expect_text "$MODEL" 'if (normalized === "rc") return "rc"'
expect_text "$MODEL" 'return checkoutBranch || "quattro"'
expect_text "$MODEL" 'return "quattro"'

for component in "$PLUGIN_DIR"/*.qml; do
  qmllint -I /usr/share/omarchy/quickshell "$component"
  if (( $(wc -l < "$component") > 250 )); then
    fail "${component#$PLUGIN_DIR/} exceeds the 250-line component boundary"
  fi
done

if rg -q '\bbar\.' "$MAIN_PAGE" "$SETTINGS_PAGE"; then
  fail "page component bypasses its explicit visual-property contract"
fi

if rg -q 'keyboard-layout-quattro-plugin|KeyboardLayout.qml|ColorDropdown.qml' \
    "$PLUGIN_DIR" --hidden --glob '!.git/**' --glob '!README.md' \
    --glob '!**/tests/test_contract.sh'; then
  fail "runtime code depends on the visual-reference plugin"
fi

echo "[ok] update channel plugin contract"
