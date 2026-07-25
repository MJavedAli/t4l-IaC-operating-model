SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

ROOT ?= live/prod/workloads/printing-api
BACKEND_CONFIG ?=
PLAN_FILE ?= tfplan

.PHONY: help fmt fmt-check validate lint security check init plan show policy apply clean

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target> [ROOT=path]\n\n"} /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## Format Terraform recursively
	terraform fmt -recursive

fmt-check: ## Check Terraform formatting without changing files
	terraform fmt -check -recursive -diff

validate: ## Initialise without backends and validate every Terraform directory
	./scripts/validate-all.sh

lint: ## Run TFLint recursively
	tflint --init
	tflint --recursive

security: ## Run Trivy IaC security checks
	trivy config --severity HIGH,CRITICAL --exit-code 1 .

check: fmt-check validate lint security ## Run local quality gates

init: ## Initialise ROOT; pass BACKEND_CONFIG for remote state
	@if [[ -n "$(BACKEND_CONFIG)" ]]; then \
		terraform -chdir="$(ROOT)" init -input=false -backend-config="$(BACKEND_CONFIG)"; \
	else \
		terraform -chdir="$(ROOT)" init -input=false -backend=false; \
	fi

plan: ## Create a saved plan for ROOT
	terraform -chdir="$(ROOT)" plan -input=false -out="$(PLAN_FILE)"

show: ## Render the saved plan as JSON
	terraform -chdir="$(ROOT)" show -json "$(PLAN_FILE)" > "$(ROOT)/plan.json"

policy: show ## Evaluate the saved plan with Conftest
	conftest test "$(ROOT)/plan.json" --policy policies

apply: ## Apply the saved plan; production use should be CI-only
	@echo "WARNING: production applies should run through the protected GitHub workflow."
	terraform -chdir="$(ROOT)" apply "$(PLAN_FILE)"

clean: ## Remove generated local artefacts
	find . -type d -name .terraform -prune -exec rm -rf {} +
	find . -type f \( -name tfplan -o -name plan.json -o -name plan.txt \) -delete
