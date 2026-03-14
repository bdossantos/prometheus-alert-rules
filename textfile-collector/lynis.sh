#!/usr/bin/env bash
#
# Textfile collector for Lynis audit tool reports
# https://github.com/CISOfy/lynis
#
# Default report location: /var/log/lynis-report.dat
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

LYNIS_REPORT="${LYNIS_REPORT:-/var/log/lynis-report.dat}"

if [[ ! -f "${LYNIS_REPORT}" ]]; then
  echo "${0##*/}: Lynis report file not found: ${LYNIS_REPORT}" >&2
  exit 1
fi

get_value() {
  local key="$1"
  local value=""
  value=$(grep "^${key}=" "${LYNIS_REPORT}" | tail -1 | cut -d'=' -f2-) || true
  echo "${value}"
}

count_entries() {
  local key="$1"
  local count=0
  count=$(grep -c "^${key}\[\]=" "${LYNIS_REPORT}") || true
  echo "${count}"
}

lynis_version="$(get_value 'lynis_version')"
hardening_index="$(get_value 'hardening_index')"
tests_performed="$(get_value 'tests_performed')"
warnings_count="$(count_entries 'warning')"
suggestions_count="$(count_entries 'suggestion')"

# Convert report datetime to unix timestamp
report_datetime="$(get_value 'report_datetime_start')"
last_run=0
if [[ -n "${report_datetime}" ]]; then
  last_run=$(date -d "${report_datetime}" '+%s' 2>/dev/null) || last_run=0
fi

cat <<EOF
# HELP lynis_version Lynis version information
# TYPE lynis_version gauge
lynis_version{version="${lynis_version}"} 1
# HELP lynis_hardening_index Lynis hardening index (0-100)
# TYPE lynis_hardening_index gauge
lynis_hardening_index ${hardening_index:-0}
# HELP lynis_tests_performed Number of tests performed by Lynis
# TYPE lynis_tests_performed gauge
lynis_tests_performed ${tests_performed:-0}
# HELP lynis_warnings Number of warnings found by Lynis
# TYPE lynis_warnings gauge
lynis_warnings ${warnings_count}
# HELP lynis_suggestions Number of suggestions found by Lynis
# TYPE lynis_suggestions gauge
lynis_suggestions ${suggestions_count}
# HELP lynis_last_run_timestamp Unix timestamp of the last Lynis run
# TYPE lynis_last_run_timestamp gauge
lynis_last_run_timestamp ${last_run}
EOF
