local sys = require "luci.sys"
local mdl = (sys.exec("cat /tmp/sysinfo/model 2>/dev/null") or "Xiaomi MiWiFi Mini"):gsub("[\r\n]", "")
local arch = (sys.exec("uname -m 2>/dev/null") or "mips"):gsub("[\r\n]", "")
local lan = (sys.exec("uci -q get network.lan.ipaddr") or "192.168.1.1"):gsub("[\r\n]", "")

local info_bar = string.format(
    '<div style="margin-bottom:10px;padding:8px 12px;background:#022c22;border:1px solid #eab308;border-radius:6px;color:#fef08a;font-weight:bold;">Model: %s | Arch: %s (mt7620) | LAN: %s</div>',
    mdl, arch, lan
)

local m = Map("wireless", translate("QWAIRAH Quick Setup"), info_bar .. translate("5GHz on radio0 (802.11ac: 5180-5885MHz, VHT20/40/80) & 2.4GHz on radio1 (802.11n: Ch 1-13, HT20/40)"))

local s0 = m:section(NamedSection, "default_radio0", "wifi-iface", translate("5GHz Interface (QWAIRAH 5G - radio0)"))
local o = s0:option(ListValue, "mode", translate("Mode"))
o:value("ap", "AP WDS"); o:value("sta", "Client WDS"); o:value("mesh", "802.11s Mesh")
o = s0:option(Flag, "wds", translate("WDS")); o.default = "1"
o = s0:option(Value, "ssid", translate("SSID")); o.default = "QWAIRAH 5G"
o = s0:option(ListValue, "encryption", translate("Encryption"))
o:value("none", "Open (No Password)"); o:value("psk2", "WPA2-PSK"); o:value("sae-mixed", "WPA2/WPA3")
o = s0:option(Value, "key", translate("Password")); o:depends("encryption", "psk2"); o:depends("encryption", "sae-mixed")

local r0 = m:section(NamedSection, "radio0", "wifi-device", translate("5GHz Radio Settings (802.11ac - radio0)"))
o = r0:option(ListValue, "country", translate("Country")); o:value("PA", "Panama (PA)"); o:value("DE", "Germany (DE)"); o:value("GB", "United Kingdom (GB)"); o:value("US", "United States (US)")
o = r0:option(Value, "channel", translate("Channel (36-165 / 5180-5885MHz)")); o.default = "104"
o = r0:option(ListValue, "htmode", translate("Channel Width (AC)"))
o:value("VHT20", "20MHz (VHT20)"); o:value("VHT40", "40MHz (VHT40)"); o:value("VHT80", "80MHz (VHT80)")
o = r0:option(Value, "txpower", translate("TX Power (dBm - Clamped by Hardware/RegDB)")); o.default = "23"

if m.uci:get("wireless", "default_radio1") then
    local s1 = m:section(NamedSection, "default_radio1", "wifi-iface", translate("2.4GHz Interface (QWAIRAH 2G - radio1)"))
    o = s1:option(ListValue, "mode", translate("Mode"))
    o:value("ap", "AP WDS"); o:value("sta", "Client WDS"); o:value("mesh", "802.11s Mesh")
    o = s1:option(Flag, "wds", translate("WDS")); o.default = "1"
    o = s1:option(Value, "ssid", translate("SSID")); o.default = "QWAIRAH 2G"
    o = s1:option(ListValue, "encryption", translate("Encryption"))
    o:value("none", "Open (No Password)"); o:value("psk2", "WPA2-PSK"); o:value("sae-mixed", "WPA2/WPA3")
    o = s1:option(Value, "key", translate("Password")); o:depends("encryption", "psk2"); o:depends("encryption", "sae-mixed")

    local r1 = m:section(NamedSection, "radio1", "wifi-device", translate("2.4GHz Radio Settings (802.11n - radio1)"))
    o = r1:option(ListValue, "country", translate("Country")); o:value("PA", "Panama (PA)"); o:value("DE", "Germany (DE)"); o:value("GB", "United Kingdom (GB)"); o:value("US", "United States (US)")
    o = r1:option(Value, "channel", translate("Channel (1-13)")); o.default = "6"
    o = r1:option(ListValue, "htmode", translate("Channel Width (N)"))
    o:value("HT20", "20MHz (HT20)"); o:value("HT40", "40MHz (HT40)")
    o = r1:option(Value, "txpower", translate("TX Power (dBm - Clamped by Hardware/RegDB)")); o.default = "20"
end

function m.on_after_commit(self)
    sys.call("/sbin/wifi reload >/dev/null 2>&1 &")
end
return m
