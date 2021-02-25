# prometheus-alert-rules

[![CI](https://github.com/bdossantos/prometheus-alert-rules/actions/workflows/ci.yml/badge.svg)](https://github.com/bdossantos/prometheus-alert-rules/actions/workflows/ci.yml)

## Usage

```yaml
# prometheus.yml

global:
  scrape_interval: 15s
  ...

rule_files:
  - 'alerts/*.yml'

scrape_configs:
  ...
```
