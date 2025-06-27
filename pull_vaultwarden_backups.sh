#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Load secrets from .env.local (if present)                                   #
###############################################################################
if [[ -f "$(dirname "$0")/.env.local" ]]; then          # script directory
  # export every name=value pair found in the file
  set -o allexport
  source "$(dirname "$0")/.env.local"
  set +o allexport
else
  echo "⚠️  .env.local not found – falling back on existing env vars"
fi

###############################################################################
# 1. Pull Vaultwarden backups via rsync                                        #
###############################################################################
mkdir -p "$LOCAL_DIR"

echo "Pulling backups from ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR} → ${LOCAL_DIR} ..."
rsync -avz -e "ssh -i $SSH_KEY" \
      "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
      "${LOCAL_DIR}/"
echo "✔ Backups copied."

###############################################################################
# 2. Resource-usage snapshot (local + remote)                                  #
###############################################################################
# Local
local_hostname=$(hostname)
local_uptime=$(uptime -p 2>/dev/null || echo "N/A")
local_load=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | xargs || echo "N/A")
local_mem=$(free -h 2>/dev/null | awk '/Mem:/ {print $3 "/" $2 " used (" int($3/$2*100) "%)"}' || echo "N/A")
local_disk=$(df -h / | awk 'NR==2 {print $3 "/" $2 " used (" $5 ")"}')
local_disk_percent=$(echo "$local_disk" | grep -oE '[0-9]+')

[[ $local_disk_percent -ge 80 ]] && local_disk+=" [***IMPORTANT***]"

# Remote (single SSH helper to avoid repetition)
ssh_remote() { ssh -i "$SSH_KEY" -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" "$@"; }

remote_hostname=$(ssh_remote hostname 2>/dev/null || echo "N/A")
remote_uptime=$(ssh_remote 'uptime -p' 2>/dev/null || echo "N/A")
remote_load=$(ssh_remote "uptime | awk -F'load average:' '{print \$2}'" | xargs || echo "N/A")
remote_mem=$(ssh_remote "free -h | awk '/Mem:/ {print \$3 \"/\" \$2 \" used (\" int(\$3/\$2*100) \"%)\"}'" || echo "N/A")
remote_disk=$(ssh_remote "df -h / | awk 'NR==2 {print \$3 \"/\" \$2 \" used (\" \$5 \")\"}'")
remote_disk_percent=$(echo "$remote_disk" | grep -oE '[0-9]+')

[[ $remote_disk_percent -ge 50 ]] && remote_disk+=" [***IMPORTANT***]"

###############################################################################
# 3. Pending security updates                                                 #
###############################################################################
sudo apt-get update -qq
local_sec=$(apt list --upgradable 2>/dev/null | grep -c '\-security')
[[ $local_sec -gt 0 ]] && local_sec="[${local_sec} SECURITY UPDATES PENDING]" || local_sec="[Server is up-to-date]"

ssh_remote 'apt-get update -qq'
remote_sec=$(ssh_remote "apt list --upgradable 2>/dev/null | grep -c '\-security'")
[[ $remote_sec -gt 0 ]] && remote_sec="[${remote_sec} SECURITY UPDATES PENDING]" || remote_sec="[Server is up-to-date]"

###############################################################################
# 4. Compose and send the email                                               #
###############################################################################
body=$(cat <<EOF
Vaultwarden Backup Summary
==========================

Local Host: $local_hostname
---------------------------
Uptime:       $local_uptime
CPU Load:     $local_load
Memory Usage: $local_mem
Disk Usage:   $local_disk
Security:     $local_sec

Remote Host: $remote_hostname
-----------------------------
Uptime:       $remote_uptime
CPU Load:     $remote_load
Memory Usage: $remote_mem
Disk Usage:   $remote_disk
Security:     $remote_sec

Backup Files Pulled to: $LOCAL_DIR
EOF
)

echo "$body" | s-nail -v \
  -s "$MAIL_SUBJECT" \
  -r "$FROM_ADDR" \
  -S "smtp=smtp://${SMTP_SERVER}:${SMTP_PORT}" \
  -S smtp-use-starttls \
  -S ssl-verify=ignore \
  -S smtp-auth=login \
  -S smtp-auth-user="$SMTP_USER" \
  -S smtp-auth-password="$SMTP_PASS" \
  "$TO_ADDR"

echo "✔ Email sent from ${FROM_ADDR} to ${TO_ADDR}"
