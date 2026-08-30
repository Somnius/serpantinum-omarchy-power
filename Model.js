function clamp(value, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number)) return minimum
  return Math.max(minimum, Math.min(maximum, number))
}

function batteryFraction(device) {
  return device && device.isPresent ? clamp(device.percentage, 0, 1) : 0
}

function batteryState(device, onBattery, states) {
  var d = device || {}
  var s = states || {}
  if (!d.isPresent) return "desktop"
  if (d.state === s.FullyCharged || (!onBattery && batteryFraction(d) >= 0.995)) return "full"
  if (d.state === s.PendingCharge) return "holding"
  if (!onBattery && d.state === s.Charging) return "charging"
  if (onBattery || d.state === s.Discharging) return "discharging"
  return "idle"
}

function stateLabel(state) {
  if (state === "desktop") return "AC POWER"
  if (state === "full") return "FULLY CHARGED"
  if (state === "holding") return "CHARGE LIMIT"
  if (state === "charging") return "CHARGING"
  if (state === "discharging") return "ON BATTERY"
  return "POWER CONNECTED"
}

function batteryIcon(state, fraction) {
  if (state === "desktop") return "󰚥"
  if (state === "charging") return "󰂄"
  if (state === "full") return "󰁹"
  var icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
  return icons[Math.min(9, Math.floor(clamp(fraction, 0, 1) * 10))]
}

function parseKeyValue(raw) {
  var result = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var separator = lines[i].indexOf("\t")
    if (separator <= 0) continue
    var key = lines[i].substring(0, separator).trim()
    if (key) result[key] = lines[i].substring(separator + 1).trim()
  }
  return result
}

function parseProfiles(raw) {
  var profiles = []
  var active = ""
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    var fields = line.split("\t")
    var profile = fields[0].trim()
    if (!profile || profiles.indexOf(profile) >= 0) continue
    profiles.push(profile)
    if (fields[1] === "1") active = profile
  }
  return { profiles: profiles, active: active }
}

function profileIcon(profile) {
  if (profile === "performance") return "󰓅"
  if (profile === "balanced") return "󰊚"
  if (profile === "power-saver") return "󰌪"
  return "󰂄"
}

function formatProfile(profile) {
  return String(profile || "").split("-").map(function(part) {
    return part ? part.charAt(0).toUpperCase() + part.substring(1) : ""
  }).join(" ")
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp: clamp,
    batteryFraction: batteryFraction,
    batteryState: batteryState,
    stateLabel: stateLabel,
    batteryIcon: batteryIcon,
    parseKeyValue: parseKeyValue,
    parseProfiles: parseProfiles,
    profileIcon: profileIcon,
    formatProfile: formatProfile
  }
}
