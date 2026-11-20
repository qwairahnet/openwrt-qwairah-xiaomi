local m, s, o, sys = Map("qwairah_bot", translate("Scheduled Reboot"), translate("Automatic periodic reboot (Asia/Aden)")), nil, nil, require "luci.sys"
s = m:section(NamedSection, "schedule", "schedule", translate("Reboot Schedule"))
o = s:option(Flag, "enabled", translate("Enable Auto Reboot")); o.default = "0"
o = s:option(Value, "hour", translate("Hour (0-23)")); o.default = "4"
o = s:option(Value, "minute", translate("Minute (0-59)")); o.default = "0"

function m.on_after_commit(self)
    local en = m.uci:get("qwairah_bot", "schedule", "enabled") or "0"
    local hr = m.uci:get("qwairah_bot", "schedule", "hour") or "4"
    local mn = m.uci:get("qwairah_bot", "schedule", "minute") or "0"
    sys.call("sed -i '/qwairah_auto_reboot/d' /etc/crontabs/root 2>/dev/null || true")
    if en == "1" then
        sys.call(string.format("echo '%s %s * * * /sbin/reboot # qwairah_auto_reboot' >> /etc/crontabs/root", mn, hr))
    end
    sys.call("/etc/init.d/cron enable && /etc/init.d/cron restart >/dev/null 2>&1")
end
return m
