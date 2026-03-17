CWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(HOME)/.local/bin:$(HOME)/bin:/usr/local/bin:/bin:$(PATH)
SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help

export PATH

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

test: ## Run tests suite
	@docker run --entrypoint /bin/sh -v $(CWD)/rules:/rules:ro prom/prometheus:v3.10.0@sha256:4a61322ac1103a0e3aea2a61ef1718422a48fa046441f299d71e660a3bc71ae9 -c '/bin/find /rules -type f -name *.yml | xargs -n 1 -P 1 promtool check rules'

shellcheck: ## Run shellcheck on textfile-collector directory
	$(info --> Run shellsheck)
	find textfile-collector -type f \
		| xargs -n 1 -P 1 -I % shellcheck %
