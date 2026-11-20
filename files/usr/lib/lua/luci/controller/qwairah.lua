module("luci.controller.qwairah", package.seeall)

function index()
    entry({"admin", "qwairah"}, firstchild(), _("QWAIRAH"), 15).dependent = false
    entry({"admin", "qwairah", "quicksetup"}, cbi("qwairah_quick"), _("Quick Setup"), 1)
    entry({"admin", "qwairah", "scan"}, template("qwairah/scan"), _("Channel Scan"), 2)
    entry({"admin", "qwairah", "tools"}, template("qwairah/tools"), _("Ping, Speed & Ports"), 3)
    entry({"admin", "qwairah", "schedule"}, cbi("qwairah_sched"), _("Scheduled Reboot"), 4)
    entry({"admin", "qwairah", "telegram"}, cbi("qwairah_tg"), _("Telegram Bot"), 5)
    entry({"admin", "services"}, firstchild(), _("Services"), 40).dependent = false
    entry({"admin", "services", "qwairah_tg"}, cbi("qwairah_tg"), _("Telegram Bot"), 95)

    entry({"admin", "qwairah", "api_scan"}, call("action_scan")).leaf = true
    entry({"admin", "qwairah", "api_ping"}, call("action_ping")).leaf = true
    entry({"admin", "qwairah", "api_speed"}, call("action_speed")).leaf = true
end

function action_scan()
    local sys = require "luci.sys"
    local band = luci.http.formvalue("band") or "5g"
    local dev = (band == "5g") and "wlan0" or "wlan1"
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        output = sys.exec("iw dev " .. dev .. " scan 2>/dev/null | awk '/BSS /{b=$2} /SSID:/{s=$2} /signal:/{print \"Signal:\", $2, $3, \"| SSID:\", s, \"| BSSID:\", b}' | sort -k2 -n -r || iwinfo " .. dev .. " scan 2>/dev/null")
    })
end

function action_ping()
    local sys = require "luci.sys"
    local host = (luci.http.formvalue("host") or "1.1.1.3"):gsub("[^a-zA-Z0-9%.%-]", "")
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        output = sys.exec("ping -c 4 -W 2 " .. host .. " 2>&1")
    })
end

function action_speed()
    local sys = require "luci.sys"
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        output = sys.exec("curl -s -w 'Download Speed: %{speed_download} bytes/sec | Time: %{time_total}s | HTTP Code: %{http_code}\n' -o /dev/null --max-time 15 http://speed.cloudflare.com/__down?bytes=10000000 2>&1")
    })
end
