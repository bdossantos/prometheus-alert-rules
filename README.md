# prometheus-alert-rules

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
