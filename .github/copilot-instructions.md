# Copilot Instructions

## Repository Overview

This repository contains Prometheus alert rules, SLO specifications, and textfile collector scripts for node exporter.

## Repository Structure

```
.
├── rules/                  # Prometheus alert rule files (YAML)
├── slo-specs/              # SLO specification files (Sloth format, YAML)
├── slo-rules/              # Generated SLO Prometheus rules (do not edit manually)
├── textfile-collector/     # Shell scripts for node_exporter textfile collector
├── Makefile                # Test and lint targets
└── README.md
```

## Alert Rule Files (`rules/`)

Each file in `rules/` is a valid Prometheus rule file. Files are named after the component or system they monitor (e.g., `cpu.yml`, `disk.yml`, `mysql.yml`).

### Structure

```yaml
---
groups:
  - name: <GroupName>
    rules:
      - alert: <AlertName>
        expr: <PromQL expression>
        for: <duration>
        labels:
          severity: <page|warning|info>
        annotations:
          summary: <short description (instance {{ $labels.instance }})>
          description: "<detailed description>\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```

### Conventions

- Alert names use `CamelCase`.
- Group names are lowercase (matching the filename without extension), except where a proper noun is used.
- Severity labels are one of: `page`, `warning`, `info`.
- PromQL expressions that use node metrics typically enrich with hostname using:
  ```
  * on(instance) group_left (nodename) node_uname_info{nodename=~".+"}
  ```
- Wrap the main expression in parentheses before the enrichment join.
- `summary` annotations follow the pattern: `<Human readable description> (instance {{ $labels.instance }})`.
- `description` annotations include `VALUE = {{ $value }}` and `LABELS = {{ $labels }}`.

## SLO Specifications (`slo-specs/`)

SLO specs use the [Sloth](https://github.com/slok/sloth) format:

```yaml
version: prometheus/v1
service: <service-name>
labels:
  repo: https://github.com/bdossantos/prometheus-alert-rules
slos:
  - name: requests-availability
    objective: 99.9
    description: <description>
    sli:
      events:
        error_query: <PromQL>
        total_query: <PromQL>
    alerting:
      name: <AlertName>
      page_alert:
        labels:
          severity: page
```

## SLO Rules (`slo-rules/`)

These files are **auto-generated** by Sloth. Do not edit them manually. Regenerate with:

```sh
sloth generate -i slo-specs/ -o slo-rules/
prettier -w slo-rules/*
```

## Textfile Collector Scripts (`textfile-collector/`)

Shell scripts intended to be used with [node_exporter's textfile collector](https://github.com/prometheus/node_exporter#textfile-collector). Scripts must pass `shellcheck`.

## Development Workflow

### Run tests (validates all rule files using `promtool`)

```sh
make test
```

This runs `promtool check rules` on all files in `rules/` via Docker.

### Run shellcheck on textfile-collector scripts

```sh
make shellcheck
```

### Add a new alert rule

1. Add or edit the appropriate YAML file in `rules/`.
2. Run `make test` to validate the rule syntax.
3. Follow the existing structure: `groups` → `rules` → `alert`, `expr`, `for`, `labels`, `annotations`.

### Add a new SLO

1. Create a new SLO spec file in `slo-specs/` following the Sloth format.
2. Regenerate `slo-rules/` with `sloth generate -i slo-specs/ -o slo-rules/`.
3. Format with `prettier -w slo-rules/*`.

## Git Commit Messages

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type       | When to use                                               |
| ---------- | --------------------------------------------------------- |
| `feat`     | A new alert rule, SLO, or textfile collector script       |
| `fix`      | A bug fix in an existing rule, SLO, or script             |
| `docs`     | Documentation changes only (README, comments, etc.)      |
| `style`    | Formatting changes that do not affect meaning             |
| `refactor` | Code change that neither fixes a bug nor adds a feature   |
| `test`     | Adding or updating tests                                  |
| `chore`    | Maintenance tasks (CI config, Makefile, dependencies)     |

### Examples

```
feat(rules): add HostOomKillDetected alert
fix(rules): correct threshold for HostHighCpuLoad
docs: update README with new alert descriptions
chore(ci): update promtool Docker image version
```
