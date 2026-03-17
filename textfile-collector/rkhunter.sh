#!/usr/bin/env bash
#
# Textfile collector for rkhunter (Rootkit Hunter)
# https://rkhunter.sourceforge.net/
#
# Default log location: /var/log/rkhunter.log
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

RKHUNTER_LOG="${RKHUNTER_LOG:-/var/log/rkhunter.log}"

if [[ ! -f "${RKHUNTER_LOG}" ]]; then
  echo "${0##*/}: rkhunter log file not found: ${RKHUNTER_LOG}" >&2
  exit 1
fi

# Extract rkhunter version from the log header line:
# [ Rootkit Hunter version X.Y.Z ]
rkhunter_version="$(grep -m 1 'Rootkit Hunter version' "${RKHUNTER_LOG}" \
  | sed 's/.*Rootkit Hunter version \([^ ]*\).*/\1/')" || true
rkhunter_version="${rkhunter_version:-unknown}"

# Count warnings (lines containing "Warning:"); grep -c exits 1 when no matches
warnings_count="$(grep -c 'Warning:' "${RKHUNTER_LOG}" || true)"

# Extract last run start timestamp from the log header line, e.g.:
# [20:01:01] Info: Start date is Mon Jan  6 20:01:01 2025
last_run=0
start_date="$(grep -m 1 'Start date is' "${RKHUNTER_LOG}" \
  | sed 's/.*Start date is //')" || true
if [[ -n "${start_date}" ]]; then
  last_run=$(date -d "${start_date}" '+%s' 2>/dev/null) || last_run=0
fi

cat <<EOF
# HELP rkhunter_version rkhunter version information
# TYPE rkhunter_version gauge
rkhunter_version{version="${rkhunter_version}"} 1
# HELP rkhunter_last_run_timestamp Unix timestamp of the last rkhunter run
# TYPE rkhunter_last_run_timestamp gauge
rkhunter_last_run_timestamp ${last_run}
# HELP rkhunter_warnings_total Number of warnings found by rkhunter
# TYPE rkhunter_warnings_total gauge
rkhunter_warnings_total ${warnings_count}
EOF
