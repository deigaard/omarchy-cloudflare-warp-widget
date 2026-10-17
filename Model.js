.pragma library

// Nerd-font shield glyphs. The WARP shield logo is a circle; we express state
// with the standard shield set so it renders under any Nerd Font.
var ICON_CONNECT  = "\uf075f"   // shield-check (mdi): connected
var ICON_DISCONN  = "\uf0764"   // shield-cross (mdi): disconnected
var ICON_PENDING  = "\uf0101"   // shield-alt (far): connecting / disconnecting
var ICON_ALERT    = "\uf07cd"   // shield-alert (mdi): error / needs attention

var STATUS_TEXT = {
  "Connected": "Connected",
  "Disconnected": "Disconnected",
  "Connecting": "Connecting",
  "Disconnecting": "Disconnecting",
  "Paused": "Paused",
  "Disabled": "Disabled",
  "Unregistered": "Unregistered",
  "Unknown": "Unknown"
}

// Reason strings from `warp-cli --json status` reason field.
var REASON_TEXT = {
  "NetworkHealthy": "Network healthy",
  "NetworkUnhealthy": "Network unhealthy",
  "UserDisconnect": "User disconnected",
  "ServiceNotRunning": "Service not running",
  "DisconnectedForUpdates": "Disconnected for updates",
  "SwitchingModes": "Switching modes",
  "NeedsAuthentication": "Needs authentication",
  "LicenseCheckFailed": "License check failed",
  "Unregistered": "Not registered"
}

// Color role per state: returns one of the theme tokens passed in by Panel.
function colorForStatus(status, palette) {
  palette = palette || {}
  var ok = palette.ok   || "#23d18b"   // success/green accent-ish via foreground
  var bad = palette.bad || "#f85149"   // error/red
  var warn = palette.warn || "#d9822b" // warning/orange
  switch (status) {
    case "Connected":        return ok
    case "Disconnected":     return bad
    case "Unregistered":     return bad
    case "Connecting":
    case "Disconnecting":
    case "SwitchingModes":   return warn
    default:                 return warn
  }
}

function iconForStatus(status) {
  switch (status) {
    case "Connected":        return ICON_CONNECT
    case "Disconnected":     return ICON_DISCONN
    case "Unregistered":
    case "Disabled":
    case "Paused":           return ICON_ALERT
    case "Connecting":
    case "Disconnecting":    return ICON_PENDING
    case "SwitchingModes":   return ICON_PENDING
    default:                 return ICON_DISCONN
  }
}

function statusLabel(status) {
  return STATUS_TEXT[String(status) || ""] || (String(status) || "Unknown")
}

function reasonLabel(reason) {
  if (!reason) return ""
  return REASON_TEXT[String(reason) || ""] || String(reason)
    .replace(/([A-Z])/g, " $1").replace(/^ +/, "").toLowerCase()
    .replace(/^./, function(c){ return c.toUpperCase() })
}

function accountLabel(account) {
  switch (account) {
    case "ZeroTrust": return "Cloudflare Zero Trust"
    case "Consumer":  return "Cloudflare WARP (Consumer)"
    default:          return "Unknown account"
  }
}

function modeLabel(mode) {
  switch (mode) {
    case "WarpWithDnsOverHttps": return "WARP + DoH"
    case "WarpWithDot":          return "WARP + DoT"
    case "Warp":                 return "WARP"
    case "DoH":                  return "DNS over HTTPS"
    case "DoT":                  return "DNS over TLS"
    case "TunnelOnly":           return "Tunnel only"
    case "Proxy":                return "SOCKS5 proxy"
    default:                     return mode ? String(mode) : "—"
  }
}

function connected(status) {
  return status === "Connected"
}

function isTerminalError(error) {
  return error === "service" || error === "unregistered"
}
