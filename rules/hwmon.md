---
groups:
  - name: Hardware
    rules:
      - alert: HighHwmonTemp
        expr: node_hwmon_temp_celsius > 75
        for: 5m
        labels:
          severity: warning
        annotations:
          description: "{{ $labels.job }} on '{{ $labels.job }}' temperature is at {{ humanize $value }}%."
          summary: High temperature for '{{ $labels.job }}'
      - alert: HwmonTempCritAlarm
        expr: node_hwmon_temp_crit_alarm_celsius > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          description: "{{ $labels.job }} on '{{ $labels.job }}' temperature alarm"
          summary: Temperature is critical for '{{ $labels.job }}'
