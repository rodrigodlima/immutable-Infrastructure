# Immutable Infrastructure - multi-cloud shortcuts
#
# Usage: make <target> [CLOUD=gcp|aws|azure]
# CLOUD defaults to gcp.

CLOUD ?= gcp
DEPLOY := ./bin/deploy.sh --cloud $(CLOUD)

.PHONY: help validate build deploy full update list destroy demo fmt

help: ## Show this help
	@echo "Immutable Infrastructure (CLOUD=$(CLOUD))"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Example: make full CLOUD=aws"

validate: ## Check tooling, credentials and templates
	$(DEPLOY) --validate

build: ## Build the machine image with Packer
	$(DEPLOY) --packer

deploy: ## Provision infrastructure with Terraform
	$(DEPLOY) --terraform

full: ## Build image + provision infrastructure
	$(DEPLOY) --full

update: ## Replace the running instance with the newest image
	$(DEPLOY) --update

list: ## List images built for this cloud
	$(DEPLOY) --list

destroy: ## Destroy all Terraform-managed resources
	$(DEPLOY) --destroy

demo: ## Run the end-to-end demo (GCP only)
	./bin/run-demo.sh

fmt: ## Format Terraform and Packer files
	terraform fmt -recursive clouds/
	@for t in clouds/*/packer/*.pkr.hcl; do [ -e "$$t" ] && packer fmt "$$t"; done; true
