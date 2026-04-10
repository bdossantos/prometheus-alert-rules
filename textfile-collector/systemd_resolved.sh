#!/usr/bin/env bash
#
# Textfile collector for systemd-resolved DNS statistics
# https://www.freedesktop.org/software/systemd/man/latest/resolvectl.html
#
# Parses output of `resolvectl statistics` (or `systemd-resolve --statistics`
# on older systems) and exposes metrics for node_exporter's textfile collector.
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

# Determine the correct command to use
RESOLVECTL=""
if command -v resolvectl &>/dev/null; then
  RESOLVECTL="resolvectl statistics"
elif command -v systemd-resolve &>/dev/null; then
  RESOLVECTL="systemd-resolve --statistics"
else
  echo "${0##*/}: neither resolvectl nor systemd-resolve found in PATH" >&2
  exit 1
fi

# Collect statistics output
stats="$(${RESOLVECTL} 2>/dev/null)" || {
  echo "${0##*/}: failed to run ${RESOLVECTL}" >&2
  exit 1
}

# Helper: extract a numeric value for a given key from the statistics output.
# Matches lines like "  Current Transactions: 42" and returns the number.
get_stat() {
  local key="$1"
  local value=""
  value=$(echo "${stats}" | grep -m 1 "${key}:" | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $NF); print $NF}') || true
  echo "${value:-0}"
}

# --- Transactions ---
transactions_current="$(get_stat 'Current Transactions')"
transactions_total="$(get_stat 'Total Transactions')"

# --- Cache ---
cache_current_size="$(get_stat 'Current Cache Size')"
cache_hits="$(get_stat 'Cache Hits')"
cache_misses="$(get_stat 'Cache Misses')"

# --- Failure Transactions ---
# "Total Timeouts:" vs "Total Timeouts (Stale Data Served):"
# Use exact match to avoid confusion between the two
timeouts_total="$(echo "${stats}" | awk '/Total Timeouts:/ && !/Stale/ {gsub(/^[ \t]+|[ \t]+$/, "", $NF); print $NF; exit}')"
timeouts_total="${timeouts_total:-0}"
timeouts_stale_total="$(get_stat 'Total Timeouts (Stale Data Served)')"

failure_responses_total="$(echo "${stats}" | awk '/Total Failure Responses:/ && !/Stale/ {gsub(/^[ \t]+|[ \t]+$/, "", $NF); print $NF; exit}')"
failure_responses_total="${failure_responses_total:-0}"
failure_responses_stale_total="$(get_stat 'Total Failure Responses (Stale Data Served)')"

# --- DNSSEC Verdicts ---
dnssec_secure="$(get_stat 'Secure')"
dnssec_insecure="$(get_stat 'Insecure')"
dnssec_bogus="$(get_stat 'Bogus')"
dnssec_indeterminate="$(get_stat 'Indeterminate')"

cat <<EOF
# HELP systemd_resolved_transactions_current Number of DNS transactions currently being processed
# TYPE systemd_resolved_transactions_current gauge
systemd_resolved_transactions_current ${transactions_current}
# HELP systemd_resolved_transactions_total Total number of DNS transactions since systemd-resolved was started
# TYPE systemd_resolved_transactions_total counter
systemd_resolved_transactions_total ${transactions_total}
# HELP systemd_resolved_cache_current_size Number of entries currently in the DNS cache
# TYPE systemd_resolved_cache_current_size gauge
systemd_resolved_cache_current_size ${cache_current_size}
# HELP systemd_resolved_cache_hits_total Number of DNS queries answered from the cache
# TYPE systemd_resolved_cache_hits_total counter
systemd_resolved_cache_hits_total ${cache_hits}
# HELP systemd_resolved_cache_misses_total Number of DNS queries that required a new lookup
# TYPE systemd_resolved_cache_misses_total counter
systemd_resolved_cache_misses_total ${cache_misses}
# HELP systemd_resolved_timeouts_total Number of DNS queries that timed out
# TYPE systemd_resolved_timeouts_total counter
systemd_resolved_timeouts_total ${timeouts_total}
# HELP systemd_resolved_timeouts_stale_total Number of DNS timeouts where stale cached data was served
# TYPE systemd_resolved_timeouts_stale_total counter
systemd_resolved_timeouts_stale_total ${timeouts_stale_total}
# HELP systemd_resolved_failure_responses_total Number of DNS queries that received a failure response
# TYPE systemd_resolved_failure_responses_total counter
systemd_resolved_failure_responses_total ${failure_responses_total}
# HELP systemd_resolved_failure_responses_stale_total Number of DNS failure responses where stale cached data was served
# TYPE systemd_resolved_failure_responses_stale_total counter
systemd_resolved_failure_responses_stale_total ${failure_responses_stale_total}
# HELP systemd_resolved_dnssec_secure_total Number of DNSSEC queries validated as secure
# TYPE systemd_resolved_dnssec_secure_total counter
systemd_resolved_dnssec_secure_total ${dnssec_secure}
# HELP systemd_resolved_dnssec_insecure_total Number of DNSSEC queries validated as insecure
# TYPE systemd_resolved_dnssec_insecure_total counter
systemd_resolved_dnssec_insecure_total ${dnssec_insecure}
# HELP systemd_resolved_dnssec_bogus_total Number of DNSSEC queries that failed validation
# TYPE systemd_resolved_dnssec_bogus_total counter
systemd_resolved_dnssec_bogus_total ${dnssec_bogus}
# HELP systemd_resolved_dnssec_indeterminate_total Number of DNSSEC queries where validation status could not be determined
# TYPE systemd_resolved_dnssec_indeterminate_total counter
systemd_resolved_dnssec_indeterminate_total ${dnssec_indeterminate}
EOF
