#!/usr/bin/env bash
#
# Textfile collector for fail2ban
# https://github.com/fail2ban/fail2ban
#
# Exposes per-jail metrics: currently banned IPs, currently failed attempts,
# total failed attempts, and total bans.
#
# Requires fail2ban-client to be available and fail2ban to be running.
#
# Formatting done via shfmt -i 2
# https://github.com/mvdan/sh

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

# Ensure predictable numeric / date formats, etc.
export LC_ALL=C

FAIL2BAN_CLIENT="${FAIL2BAN_CLIENT:-fail2ban-client}"

# Check whether fail2ban is running
if ! "${FAIL2BAN_CLIENT}" ping &>/dev/null; then
  cat <<EOF
# HELP fail2ban_up Whether fail2ban is up and running (1 = up, 0 = down)
# TYPE fail2ban_up gauge
fail2ban_up 0
EOF
  exit 0
fi

# Retrieve list of jails
jails=$("${FAIL2BAN_CLIENT}" status | grep 'Jail list:' | sed 's/.*Jail list:\s*//' | tr ',' '\n' | tr -d ' ') || true

cat <<EOF
# HELP fail2ban_up Whether fail2ban is up and running (1 = up, 0 = down)
# TYPE fail2ban_up gauge
fail2ban_up 1
# HELP fail2ban_banned_ips Number of currently banned IPs per jail
# TYPE fail2ban_banned_ips gauge
# HELP fail2ban_failed_current Number of currently failed attempts per jail
# TYPE fail2ban_failed_current gauge
# HELP fail2ban_failed_total Total number of failed attempts per jail
# TYPE fail2ban_failed_total gauge
# HELP fail2ban_total_bans Total number of bans per jail
# TYPE fail2ban_total_bans gauge
EOF

for jail in ${jails}; do
  status=$("${FAIL2BAN_CLIENT}" status "${jail}") || continue
  banned=$(echo "${status}" | grep 'Currently banned:' | awk '{print $NF}')
  failed=$(echo "${status}" | grep 'Currently failed:' | awk '{print $NF}')
  total_failed=$(echo "${status}" | grep 'Total failed:' | awk '{print $NF}')
  total_bans=$(echo "${status}" | grep 'Total banned:' | awk '{print $NF}')
  echo "fail2ban_banned_ips{jail=\"${jail}\"} ${banned:-0}"
  echo "fail2ban_failed_current{jail=\"${jail}\"} ${failed:-0}"
  echo "fail2ban_failed_total{jail=\"${jail}\"} ${total_failed:-0}"
  echo "fail2ban_total_bans{jail=\"${jail}\"} ${total_bans:-0}"
done
