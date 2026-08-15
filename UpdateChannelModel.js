.pragma library

var repositoryUrl = "https://github.com/basecamp/omarchy"

function normalizeChannel(value) {
  var channel = String(value || "").trim().toLowerCase()
  return ["stable", "rc", "edge", "dev"].indexOf(channel) !== -1
    ? channel
    : "unknown"
}

function branchFor(channel, devBranch) {
  var normalized = normalizeChannel(channel)
  if (normalized === "rc") return "rc"
  if (normalized === "dev") {
    var checkoutBranch = String(devBranch || "").trim()
    return checkoutBranch || "quattro"
  }
  return "quattro"
}

function contentOptions(channel) {
  var normalized = normalizeChannel(channel)
  var label = normalized === "unknown" ? "Omarchy" : normalized
  return [
    { value: "changelog", label: "View " + label + " changelog" },
    { value: "pulls", label: "View " + label + " pull requests" },
    { value: "issues", label: "View " + label + " issues" }
  ]
}

function destination(channel, content, devBranch) {
  var normalized = normalizeChannel(channel)
  var kind = String(content || "changelog")
  var branch = branchFor(normalized, devBranch)

  if (kind === "pulls") {
    return repositoryUrl + "/pulls?q=is%3Apr+is%3Aopen+base%3A"
      + encodeURIComponent(branch)
  }
  if (kind === "issues") return repositoryUrl + "/issues"
  if (normalized === "stable") return repositoryUrl + "/releases/latest"

  return repositoryUrl + "/commits/" + encodeURIComponent(branch)
}

function normalizeVisibility(value) {
  var mode = String(value || "").trim()
  return ["updates", "hidden", "always"].indexOf(mode) !== -1
    ? mode
    : "updates"
}

function isHexColor(value) {
  return /^#[0-9a-fA-F]{6}$/.test(String(value || "").trim())
}

function normalizeColor(value, fallback) {
  var color = String(value || "").trim().toLowerCase()
  var fallbackColor = String(fallback || "#a77bd8").trim().toLowerCase()
  return isHexColor(color) ? color : fallbackColor
}

function presetForColor(value, presets, fallback) {
  var color = normalizeColor(value, fallback)
  for (var index = 0; index < presets.length; index++) {
    if (String(presets[index].value).toLowerCase() === color) return color
  }
  return "custom"
}
