# prometheus-alert-rules

[![CI](https://github.com/bdossantos/prometheus-alert-rules/actions/workflows/ci.yml/badge.svg)](https://github.com/bdossantos/prometheus-alert-rules/actions/workflows/ci.yml)

A curated collection of Prometheus alert rules and recording rules covering a wide range of systems and services. Rules are organized by component and validated automatically with `promtool` on every commit.

## Table of Contents

- [Usage](#usage)
- [Alert Rules](#alert-rules)
- [Textfile Collector Scripts](#textfile-collector-scripts)
- [Development](#development)

## Usage

### Prometheus configuration

```yaml
# prometheus.yml

global:
  scrape_interval: 15s
  ...

rule_files:
  - 'rules/*.yml'

scrape_configs:
  ...
```

## Alert Rules

Each file in `rules/` targets a specific system or service. All alert names use `CamelCase` and include `severity` labels (`page`, `warning`, `info`).

| File | Description |
|------|-------------|
| `backup.yml` | Backup job failures and missing daily backup status |
| `blackbox.yml` | Blackbox exporter probe failures, SSL certificate expiry, and slow probes |
| `clock.yml` | Host clock skew and NTP synchronization issues |
| `consul.yml` | Consul service healthchecks, missing master nodes, and unhealthy agents |
| `cpu.yml` | High CPU load, underutilization, steal, I/O wait, and context switching |
| `disk.yml` | Disk space, inodes, read/write rates, latency, and filesystem errors |
| `docker.yml` | Container CPU, memory, volume usage, and throttle rate |
| `elasticsearch.yml` | Heap usage, disk space, cluster health, shards, and indexing/query performance |
| `galera.yml` | MySQL Galera cluster size, replication state, and flow control |
| `haproxy.yml` | HTTP error rates, connection errors, pending requests, and security blocks |
| `hwmon.yml` | Physical component temperature and overtemperature alarms |
| `jvm.yml` | JVM heap/non-heap memory, GC time, thread counts, and file descriptors |
| `kafka.yml` | Topic replicas, consumer group lag, and offset anomalies |
| `kernel.yml` | Kernel version deviations across the fleet |
| `lynis.yml` | Lynis hardening index, warnings, suggestions, and audit freshness |
| `md.yml` | Software RAID array state and disk failures |
| `memcached.yml` | Memcached availability, hit rate, evictions, memory, and connection saturation |
| `memory.yml` | Host memory, OOM kills, swap usage, and ECC errors |
| `mimir-alerts.yml` | Grafana Mimir component health, ingestion, compaction, and ruler alerts |
| `mimir-rules.yml` | Grafana Mimir recording rules for API and component metrics |
| `mysql.yml` | MySQL availability, replication lag, connections, and slow queries |
| `network.yml` | Network throughput, interface saturation, conntrack, and errors |
| `nomad.yml` | Nomad job failures, lost jobs, queued jobs, and blocked evaluations |
| `nvme.yml` | NVMe drive temperature, wear, media errors, and power-on hours |
| `php-fpm.yml` | PHP-FPM max children, listen queue, busy processes, and slow requests |
| `pressure.yml` | Linux PSI (Pressure Stall Information) for CPU, memory, and I/O |
| `prometheus-alerts.yml` | Prometheus and Alertmanager self-monitoring, target scraping, and TSDB health |
| `rabbitmq.yml` | RabbitMQ node health, memory, file descriptors, queues, and connections |
| `reboot.yml` | Node reboots and frequent reboot detection |
| `redis.yml` | Redis availability, replication, memory, connections, and backups |
| `smartd.yml` | SMART disk health, temperature, reallocated/pending sectors, and wear |
| `systemd.yml` | Systemd service crashes |
| `thumbor.yml` | Thumbor availability, error rate, response time, and storage hit ratio |
| `timezones.yml` | Sleep-peacefully timezone-based alert suppression windows |
| `up.yml` | Core component availability (API server, Cadvisor, Kubelet, node exporter, etc.) |
| `vault.yml` | HashiCorp Vault seal state, availability, and token management |

## Textfile Collector Scripts

The `textfile-collector/` directory contains shell scripts for use with [node_exporter's textfile collector](https://github.com/prometheus/node_exporter#textfile-collector). They expose metrics not natively available from exporters.

| Script | Description |
|--------|-------------|
| `lynis.sh` | Exports Lynis audit report metrics (hardening index, warnings, suggestions) |
| `nvme_metrics.sh` | Exports NVMe drive health metrics via `nvme-cli` |
| `smartmon.sh` | Exports SMART disk health metrics via `smartctl` |

Copy the scripts to your textfile collector directory (e.g. `/var/lib/node_exporter/textfile_collector/`) and schedule them via cron or a systemd timer.

## Development

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) — used to run `promtool` for rule validation
- [shellcheck](https://github.com/koalaman/shellcheck) — used to lint shell scripts

### Validate alert rules

```sh
make test
```

This runs `promtool check rules` on all files in `rules/` inside a Docker container.

### Lint textfile-collector scripts

```sh
make shellcheck
```

### Adding a new alert rule

1. Add or edit the appropriate YAML file in `rules/`.
2. Run `make test` to validate the rule syntax.
3. Follow the existing structure and conventions:

```yaml
---
groups:
  - name: <group-name>
    rules:
      - alert: <AlertName>
        expr: >
          (<PromQL expression>)
          * on(instance) group_left (nodename) node_uname_info{nodename=~".+"}
        for: <duration>
        labels:
          severity: <page|warning|info>
        annotations:
          summary: <Human readable description> (instance {{ $labels.instance }})
          description: "<detailed description>\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```
