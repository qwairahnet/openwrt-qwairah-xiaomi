local m, s, o, sys = Map("qwairah_bot", translate("Telegram Bot"), translate("Telegram Bot Token & Chat ID")), nil, nil, require "luci.sys"
s = m:section(NamedSection, "general", "settings", translate("Bot Configuration"))
o = s:option(Flag, "enabled", translate("Enable Notifications")); o.default = "1"
o = s:option(Value, "token", translate("Bot Token"))
o = s:option(Value, "chat_id", translate("Chat ID"))
o = s:option(Button, "_test", translate("Send Test Alert"))
function o.write()
    sys.call("/usr/bin/qwairah_notify.sh 'TEST ALERT' 'QWAIRAH Xiaomi MiWiFi Mini Telegram active'")
end
return m
