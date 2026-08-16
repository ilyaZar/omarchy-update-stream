import assert from "node:assert/strict"
import fs from "node:fs"
import vm from "node:vm"

const modelPath = new URL("../UpdateChannelModel.js", import.meta.url)
const source = fs.readFileSync(modelPath, "utf8")
  .replace(/^\.pragma library\s*/, "")
const model = { encodeURIComponent }

vm.createContext(model)
vm.runInContext(source, model, { filename: modelPath.pathname })

assert.equal(model.normalizeChannel(" EDGE\n"), "edge")
assert.equal(model.normalizeChannel("future"), "unknown")
assert.equal(model.branchFor("stable", ""), "quattro")
assert.equal(model.branchFor("rc", ""), "rc")
assert.equal(model.branchFor("edge", ""), "quattro")
assert.equal(model.branchFor("dev", "feature-test"), "feature-test")
assert.equal(model.branchFor("dev", ""), "quattro")

assert.equal(
  model.destination("stable", "changelog", ""),
  "https://github.com/basecamp/omarchy/releases/latest"
)
assert.equal(
  model.destination("rc", "changelog", ""),
  "https://github.com/basecamp/omarchy/commits/rc"
)
assert.equal(
  model.destination("edge", "changelog", ""),
  "https://github.com/basecamp/omarchy/commits/quattro"
)
assert.equal(
  model.destination("dev", "changelog", "topic/name"),
  "https://github.com/basecamp/omarchy/commits/topic%2Fname"
)
assert.equal(
  model.destination("dev", "changelog", ""),
  "https://github.com/basecamp/omarchy/commits/quattro"
)
assert.equal(
  model.destination("rc", "pulls", ""),
  "https://github.com/basecamp/omarchy/pulls?q=is%3Apr+is%3Aopen+base%3Arc"
)
assert.equal(
  model.destination("edge", "issues", ""),
  "https://github.com/basecamp/omarchy/issues"
)

assert.equal(model.normalizeVisibility("updates"), "updates")
assert.equal(model.normalizeVisibility("hidden"), "hidden")
assert.equal(model.normalizeVisibility("always"), "always")
assert.equal(model.normalizeVisibility("invalid"), "updates")
assert.equal(model.normalizePersistentVisibility("updates"), "updates")
assert.equal(model.normalizePersistentVisibility("always"), "always")
assert.equal(model.normalizePersistentVisibility("hidden"), "updates")

assert.equal(model.isHexColor("#a77bd8"), true)
assert.equal(model.isHexColor("a77bd8"), false)
assert.equal(model.normalizeColor("#A77BD8", "#ffffff"), "#a77bd8")
assert.equal(model.normalizeColor("invalid", "#a77bd8"), "#a77bd8")
assert.equal(
  model.presetForColor("#A77BD8", [{ value: "#a77bd8" }], "#ffffff"),
  "#a77bd8"
)
assert.equal(
  model.presetForColor("#123456", [{ value: "#a77bd8" }], "#ffffff"),
  "custom"
)

assert.equal(model.updateCommand(false), "omarchy update")
assert.equal(model.updateCommand(true), "omarchy update -y")
assert.equal(model.channelCommand("edge"), "omarchy channel set edge")
assert.equal(model.channelCommand("invalid"), "")

const settings = model.normalizeSettings(
  {
    assumeYes: true,
    pulseColor: "#A77BD8",
    visibilityMode: "hidden"
  },
  "always",
  "#ffffff"
)
assert.equal(settings.assumeYes, true)
assert.equal(settings.pulseColor, "#a77bd8")
assert.equal(settings.visibilityMode, "always")
assert.equal(settings.hideRequested, true)

const invalidSettings = model.normalizeSettings(
  {
    assumeYes: "true",
    pulseColor: "invalid",
    visibilityMode: "invalid"
  },
  "always",
  "#a77bd8"
)
assert.equal(invalidSettings.assumeYes, false)
assert.equal(invalidSettings.pulseColor, "#a77bd8")
assert.equal(invalidSettings.visibilityMode, "updates")
assert.equal(invalidSettings.hideRequested, false)

const staleHiddenSetting = model.normalizeSettings(
  { visibilityMode: "hidden" },
  "hidden",
  "#a77bd8"
)
assert.equal(staleHiddenSetting.visibilityMode, "updates")
assert.equal(staleHiddenSetting.hideRequested, true)

console.log("[ok] update channel model")
