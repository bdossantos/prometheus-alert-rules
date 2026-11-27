CWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(HOME)/.local/bin:$(HOME)/bin:/usr/local/bin:/bin:$(PATH)
SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help

export PATH

# Pinned by digest, bump together with the tag.
PROMETHEUS_IMAGE := prom/prometheus:v3.10.0@sha256:4a61322ac1103a0e3aea2a61ef1718422a48fa046441f299d71e660a3bc71ae9
PINT_IMAGE := ghcr.io/cloudflare/pint:0.90.0@sha256:deb5fafba283f9c0cd3882de5936b8aacba03734c3d39088b5d0d16c2f1fa5cc

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

test: ## Validate rules with promtool and run the unit tests in tests/
	@docker run --rm --entrypoint /bin/sh -v $(CWD)/rules:/rules:ro -v $(CWD)/tests:/tests:ro $(PROMETHEUS_IMAGE) -c 'find /rules -type f -name "*.yml" | xargs -n 1 -P 1 promtool check rules && find /tests -type f -name "*.yml" | xargs -n 1 -P 1 promtool test rules'

lint: ## Lint rules with pint, offline (see .pint.hcl)
	@docker run --rm -v $(CWD):/code:ro $(PINT_IMAGE) pint --offline lint rules/

shellcheck: ## Run shellcheck on textfile-collector directory
	$(info --> Run shellsheck)
	find textfile-collector -type f \
		| xargs -n 1 -P 1 -I % shellcheck %
