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
	@docker run --entrypoint /bin/sh -v $(CWD)/rules:/rules:ro prom/prometheus:v2.12.0 -c '/bin/find /rules -type f -name *.yml | xargs -n 1 -P 1 promtool check rules'
