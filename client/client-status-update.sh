#!/bin/bash

HOSTNAME=$(hostname)
TIMESTAMP=$(date +%s)

# CPU Temperatur
TEMP_C=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMP_C=${TEMP_C:: -3}

# Load & Cores
LOAD=$(awk '{print $1}' /proc/loadavg)
CORES=$(nproc)

# RAM
RAM_TOTAL=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
RAM_FREE=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
RAM_USED=$((RAM_TOTAL - RAM_FREE))
RAM_PERCENT=$(awk "BEGIN {printf \"%.0f\", 100 * $RAM_USED / $RAM_TOTAL}")

# Disk
DISK_TOTAL=$(df -h --output=size / | tail -1 | tr -dc '0-9.')
DISK_USED=$(df -h --output=used / | tail -1 | tr -dc '0-9.')
DISK_PERCENT=$(df --output=pcent / | tail -1 | tr -dc '0-9')

# Certbot-Tage (optional)
CERT_DAYS_LEFT=null
# Zertifikatsprüfung (optional)
CERT_PATH="/opt/letsencrypt/cert/live/intranet.suechting.com/fullchain.pem"
if [ -f "$CERT_PATH" ]; then
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
    NOW_TIMESTAMP=$(date +%s)
    CERT_DAYS_LEFT=$(( (EXPIRY_TIMESTAMP - NOW_TIMESTAMP) / 86400 ))
    CERT_LINE="  \"cert_days_left\": $DAYS_LEFT,"
else
    CERT_LINE=""
fi


# APT Update Check
APT_UPDATES=$(apt list --upgradeable 2>/dev/null | grep -vE "Listing|Auflistung" | wc -l)
SEC_UPDATES=$(apt list --upgradeable 2>/dev/null | grep security | wc -l)

# Letzter erfolgreicher apt update
APT_UPDATE_DATE=""
APT_MARKER="/tmp/apt-last-update"
if [ -f "$APT_MARKER" ]; then
  APT_UPDATE_DATE=$(date -r "$APT_MARKER" +"%Y-%m-%d %H:%M:%S")
fi

# Einmal pro Stunde apt update ausführen
APT_MARKER="/tmp/apt-last-update"
NOW=$(date +%s)
DO_UPDATE=true

if [ -f "$APT_MARKER" ]; then
  LAST=$(cat "$APT_MARKER")
  DIFF=$((NOW - LAST))
  if [ $DIFF -lt 3600 ]; then
    DO_UPDATE=false
  fi
fi

if [ "$DO_UPDATE" = true ]; then
  apt update > /dev/null 2>&1
  echo $NOW > "$APT_MARKER"
fi

# System-Uptime (in Minuten)
UPTIME_RAW=$(cut -d. -f1 /proc/uptime)
UPTIME_MIN=$((UPTIME_RAW / 60))


# Neustart erforderlich?
if [ -f /var/run/reboot-required ]; then
  REBOOT_REQUIRED=true
else
  REBOOT_REQUIRED=false
fi
# Output-Datei
OUTPUT="/tmp/${HOSTNAME}_status.json"

# JSON schreiben – mit gültiger Struktur
cat <<EOF > "$OUTPUT"
{
  "host": "$HOSTNAME",
  "timestamp": $TIMESTAMP,
  "temp": $TEMP_C,
  "load": $LOAD,
  "cpu_cores": $CORES,
  "ram_total": $RAM_TOTAL,
  "ram_used": $RAM_USED,
  "ram_percent": $RAM_PERCENT,
  "disk_total": $DISK_TOTAL,
  "disk_used": $DISK_USED,
  "disk_percent": $DISK_PERCENT,
  "cert_days_left": $CERT_DAYS_LEFT,
  "apt_updates": $APT_UPDATES,
  "security_updates": $SEC_UPDATES,
  "last_apt_update": "$APT_UPDATE_DATE",
  "uptime_minutes": $UPTIME_MIN,
  "reboot_required": $REBOOT_REQUIRED
}
EOF

# Upload an deinen Server
LIVE_UPLOAD_URL="https://status.intranet.suechting.com/upload/${HOSTNAME}.json"
curl -X POST -H "Content-Type: application/json" --data-binary "@$OUTPUT" "$LIVE_UPLOAD_URL"
