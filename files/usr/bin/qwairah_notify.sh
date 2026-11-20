#!/bin/sh
EVENT="$1"
DETAIL="$2"

ENABLED=$(uci -q get qwairah_bot.general.enabled)
TOKEN=$(uci -q get qwairah_bot.general.token)
CHAT_ID=$(uci -q get qwairah_bot.general.chat_id)

[ "$ENABLED" != "1" ] || [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && exit 0

HOSTNAME=$(uci -q get system.@system[0].hostname || echo "QWAIRAH")
MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "Xiaomi MiWiFi Mini")
IPADDR=$(uci -q get network.lan.ipaddr || echo "192.168.1.1")
DHCP_STATE=$([ "$(uci -q get dhcp.lan.ignore)" = "1" ] && echo "OFF (DISABLED)" || echo "ON (ENABLED)")
WIFI_5G=$(uci -q get wireless.default_radio0.ssid || echo "QWAIRAH 5G")
WIFI_2G=$(uci -q get wireless.default_radio1.ssid || echo "QWAIRAH 2G")
PORTS=$(for d in /sys/class/net/*; do
  n=$(basename "$d")
  case "$n" in lo) continue ;; esac
  st=$(cat "$d/operstate" 2>/dev/null || echo "down")
  sp=$(cat "$d/speed" 2>/dev/null)
  [ -n "$sp" ] && [ "$sp" -gt 0 ] 2>/dev/null && printf "%s:%s(%sMb) " "$n" "$st" "$sp" || printf "%s:%s " "$n" "$st"
done)
UPTIME=$(uptime 2>/dev/null | sed 's/.*up \([^,]*\).*/\1/' || echo "-")

MSG="📡 QWAIRAH NET NOTIFICATION
━━━━━━━━━━━━━━━━━━━━
🔹 Event: ${EVENT}
📱 Model: ${MODEL}
🏷️ Host: ${HOSTNAME}
🌐 IP: ${IPADDR}
⚙️ DHCP: ${DHCP_STATE}
📶 5GHz (radio0): ${WIFI_5G} | 2.4GHz (radio1): ${WIFI_2G}
🔌 Ports: ${PORTS:-none}
⏱️ Uptime: ${UPTIME}
📝 Info: ${DETAIL}"

curl -sk --max-time 10 -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "text=${MSG}" >/dev/null 2>&1 &
