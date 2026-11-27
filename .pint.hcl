# pint (https://cloudflare.github.io/pint/) static checks, run with `make lint`.
# Only offline checks are used: no Prometheus server is needed.

parser {
  # Generated upstream (Grafana Mimir mixin) and synced as-is, so it keeps the
  # upstream `critical`/`warning` severities and its own conventions.
  exclude = ["rules/mimir-.*"]
}

# Conventions every alert in rules/ must follow (see README, "Adding a new alert rule").
rule {
  match {
    kind = "alerting"
  }

  label "severity" {
    severity = "bug"
    required = true
    # `none` is reserved for the always-firing dead man's switch.
    value    = "page|warning|info|none"
  }

  annotation "summary" {
    severity = "bug"
    required = true
  }
}
