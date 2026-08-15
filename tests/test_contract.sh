#!/bin/bash

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$PLUGIN_DIR/manifest.json"
QML="$PLUGIN_DIR/UpdateChannel.qml"
MODEL="$PLUGIN_DIR/UpdateChannelModel.js"

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
expect_text "$QML" 'if (mouseButton === Qt.LeftButton) root.runUpdate()'
expect_text "$QML" 'else if (mouseButton === Qt.RightButton) root.toggle()'
expect_text "$QML" '"omarchy update -y"'
expect_text "$QML" '"omarchy update"'
expect_text "$QML" '"omarchy channel set " + root.selectedChannel'
expect_text "$QML" '["omarchy", "update", "status"]'
expect_text "$QML" '&& selectedChannel !== currentChannel'
expect_text "$QML" 'root.linkKind = "changelog"'
expect_text "$QML" 'color: root.currentChannelColor'
expect_text "$QML" 'label: "Always show with Omarchy logo"'
expect_text "$QML" 'source: "file://" + root.omarchyPath + "/icon.png"'
expect_text "$QML" 'text: "Pulse color"'
expect_text "$QML" 'label: "Wispr Flow purple"'
expect_text "$QML" 'root.visibilityMode = persistedMode'
expect_text "$QML" 'root.pulseColor = color'
expect_text "$MODEL" 'function normalizeColor(value, fallback)'
expect_text "$MODEL" 'return repositoryUrl + "/releases/latest"'
expect_text "$MODEL" 'if (normalized === "rc") return "rc"'
expect_text "$MODEL" 'return checkoutBranch || "quattro"'
expect_text "$MODEL" 'return "quattro"'

if rg -q 'keyboard-layout-quattro-plugin|KeyboardLayout.qml|ColorDropdown.qml' \
    "$PLUGIN_DIR" --hidden --glob '!.git/**' --glob '!README.md' \
    --glob '!**/tests/test_contract.sh'; then
  fail "runtime code depends on the visual-reference plugin"
fi

echo "[ok] update channel plugin contract"
