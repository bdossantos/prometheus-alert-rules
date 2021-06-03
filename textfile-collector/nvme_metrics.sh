#!/usr/bin/env bash
#
# Based on https://raw.githubusercontent.com/prometheus-community/node-exporter-textfile-collector-scripts/master/nvme_metrics.sh
#

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

if [[ $(id -u) -ne 0 ]]; then
  echo "${0##*/}: Please run as root!" >&2
  exit 1
fi

if ! command -v nvme &>/dev/null || ! command -v jq &>/dev/null; then
  echo >&2 "jq or nvme-cli isn't installed or not in PATH"
  exit 1
fi

output_format_awk="$(
  cat <<'OUTPUTAWK'
BEGIN { v = "" }
v != $1 {
  print "# HELP nvme_" $1 " SMART metric " $1;
  if ($1 ~ /_total$/)
    print "# TYPE nvme_" $1 " counter";
  else
    print "# TYPE nvme_" $1 " gauge";
  v = $1
}
{print "nvme_" $0}
OUTPUTAWK
)"

function format_output() {
  sort | awk -F '{' "${output_format_awk}"
}

nvme_version="$(nvme version | awk '$1 == "nvme" {print $3}')"
echo "nvmecli{version=\"${nvme_version}\"} 1" | format_output

device_list="$(nvme list -o json | jq -r '.Devices | .[].DevicePath')"

for device in $device_list; do
  json_check="$(nvme smart-log -o json "${device}")"
  disk="${device##*/}"

  # The temperature value in JSON is in Kelvin, we want Celsius
  value_temperature="$(echo "$json_check" | jq '.temperature - 273')"
  echo "temperature_celsius{device=\"${disk}\"} ${value_temperature}"

  value_available_spare="$(echo "$json_check" | jq '.avail_spare / 100')"
  echo "available_spare_ratio{device=\"${disk}\"} ${value_available_spare}"

  value_available_spare_threshold="$(echo "$json_check" | jq '.spare_thresh / 100')"
  echo "available_spare_threshold_ratio{device=\"${disk}\"} ${value_available_spare_threshold}"

  value_percentage_used="$(echo "$json_check" | jq '.percent_used / 100')"
  echo "percentage_used_ratio{device=\"${disk}\"} ${value_percentage_used}"

  value_critical_warning="$(echo "$json_check" | jq '.critical_warning')"
  echo "critical_warning_total{device=\"${disk}\"} ${value_critical_warning}"

  value_media_errors="$(echo "$json_check" | jq '.media_errors')"
  echo "media_errors_total{device=\"${disk}\"} ${value_media_errors}"

  value_num_err_log_entries="$(echo "$json_check" | jq '.num_err_log_entries')"
  echo "num_err_log_entries_total{device=\"${disk}\"} ${value_num_err_log_entries}"

  value_power_cycles="$(echo "$json_check" | jq '.power_cycles')"
  echo "power_cycles_total{device=\"${disk}\"} ${value_power_cycles}"

  value_power_on_hours="$(echo "$json_check" | jq '.power_on_hours')"
  echo "power_on_hours_total{device=\"${disk}\"} ${value_power_on_hours}"

  value_controller_busy_time="$(echo "$json_check" | jq '.controller_busy_time')"
  echo "controller_busy_time_seconds{device=\"${disk}\"} ${value_controller_busy_time}"

  value_data_units_written="$(echo "$json_check" | jq '.data_units_written')"
  echo "data_units_written_total{device=\"${disk}\"} ${value_data_units_written}"

  value_data_units_read="$(echo "$json_check" | jq '.data_units_read')"
  echo "data_units_read_total{device=\"${disk}\"} ${value_data_units_read}"

  value_host_read_commands="$(echo "$json_check" | jq '.host_read_commands')"
  echo "host_read_commands_total{device=\"${disk}\"} ${value_host_read_commands}"

  value_host_write_commands="$(echo "$json_check" | jq '.host_write_commands')"
  echo "host_write_commands_total{device=\"${disk}\"} ${value_host_write_commands}"
done | format_output
