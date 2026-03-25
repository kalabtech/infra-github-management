# =============================================================================
# MAKEFILE - infra-core (multi-unit with Terragrunt)
#
# Usage:
#   make plan UNIT=unit-name          -> plan a single unit
#   make plan-all                -> plan all units
#   make apply UNIT=unit-name         -> apply a single unit
#   make resources UNIT=shared  -> list resources in a unit
# =============================================================================

# --- VARIABLES ---
UNITS_DIR  = ./units
MOD_DIR     = ./modules
UNIT       ?=
UNIT_PATH  = $(UNITS_DIR)/$(UNIT)
PLAN_FILE = terraform.tfplan
ALL_UNITS  = $(wildcard $(UNITS_DIR)/*)

# --- GUARDS ---
# Require UNIT parameter
require-unit:
	@if [ -z "$(UNIT)" ]; then \
		echo "Error: UNIT is required. Usage: make <target> UNIT=<name>"; \
		echo "Available units:"; \
		ls -1 $(UNITS_DIR); \
		exit 1; \
	fi
	@if [ ! -d "$(UNIT_PATH)" ]; then \
		echo "Error: unit '$(UNIT)' not found in $(UNITS_DIR)/"; \
		echo "Available units:"; \
		ls -1 $(UNITS_DIR); \
		exit 1; \
	fi

# Require file .env to terragrunt init
require-env:
	@test -n "$(TF_STATE_BUCKET)" || (echo "Error: TF_STATE_BUCKET not set" && exit 1)
	@test -n "$(TF_STATE_REGION)" || (echo "Error: TF_STATE_REGION not set" && exit 1)
	@test -n "$(TF_STATE_KMS)"    || (echo "Error: TF_STATE_KMS not set" && exit 1)
	@test -n "$(TF_PROJECT_NAME)" || (echo "Error: TF_PROJECT_NAME not set" && exit 1)

# --- HELPERS ---
define AWS_IDENTITY
	@echo "-----------------------"
	@echo "Current AWS Identity:"
	@AWS_PAGER="" aws sts get-caller-identity --query "Arn" --output text
	@echo "-----------------------"
endef

define TFPLAN_SUMMARY
	@chmod u+x scripts/tf-plan-summary.sh
	@./scripts/tf-plan-summary.sh $(UNIT_PATH)/$(PLAN_FILE)
	@chmod u-x scripts/tf-plan-summary.sh
endef

define GITHUB_LABELS
	@chmod u+x scripts/github_labels.sh
	@./scripts/github_labels.sh
	@chmod u-x scripts/github_labels.sh
endef

.PHONY: all init plan apply destroy resources show state output \
        init-all plan-all apply-all \
        format check lint-init prec prec-all \
        require-unit require-env units set-labels help

# =============================================================================
# SINGLE UNIT COMMANDS - require UNIT=<name>
# =============================================================================

init: require-unit require-env ## Initialize a unit - make init UNIT=unit-name
	$(AWS_IDENTITY)
	@echo "Initializing $(UNIT)..."
	@cd $(UNIT_PATH) && terragrunt init

plan: require-unit ## Plan a unit - make plan UNIT=unit-name
	$(AWS_IDENTITY)
	@echo "Planning $(UNIT)..."
	@cd $(UNIT_PATH) && terragrunt plan -out=$(PLAN_FILE)
	$(TFPLAN_SUMMARY)

apply: require-unit ## Apply a unit - make apply UNIT=unit-name
	$(AWS_IDENTITY)
	@echo "Applying $(UNIT)..."
	@cd $(UNIT_PATH) && terragrunt apply $(PLAN_FILE)

destroy: require-unit ## Destroy a unit - make destroy UNIT=unit-name
	$(AWS_IDENTITY)
	@echo "WARNING: Destroying $(UNIT)"
	@cd $(UNIT_PATH) && terragrunt destroy

resources: require-unit ## List resources - make resources UNIT=unit-name
	$(AWS_IDENTITY)
	@cd $(UNIT_PATH) && terragrunt state list

show: require-unit ## Show a resource - make show UNIT=unit-name RES=aws_iam_policy.x
	$(AWS_IDENTITY)
	@cd $(UNIT_PATH) && terragrunt state show $(RES)

state: require-unit ## Pull state - make state UNIT=unit-name
	$(AWS_IDENTITY)
	@cd $(UNIT_PATH) && terragrunt state pull

output: require-unit ## Show outputs - make output UNIT=unit-name
	$(AWS_IDENTITY)
	@cd $(UNIT_PATH) && terragrunt output -json | jq '.'

# =============================================================================
# ALL UNITS COMMANDS - uses terragrunt run-all (resolves dependencies)
# =============================================================================

init-all: require-env ## Initialize all units
	$(AWS_IDENTITY)
	@cd $(UNITS_DIR) && terragrunt run-all init

plan-all: ## Plan all units
	$(AWS_IDENTITY)
	@cd $(UNITS_DIR) && terragrunt run-all plan

apply-all: ## Apply all units
	$(AWS_IDENTITY)
	@echo "WARNING: Applying ALL units"
	@cd $(UNITS_DIR) && terragrunt run-all apply

# =============================================================================
# QUALITY AND SECURITY
# =============================================================================

format: require-unit ## Format and validate - make check UNIT=unit-name
	@echo "Formatting..."
	@terraform fmt -recursive $(UNITS_DIR)
	@terraform fmt -recursive $(MOD_DIR)
	@echo "-----------------------"
	@echo "Validating $(UNIT)..."
	@cd $(UNIT_PATH) && terragrunt validate

check: ## Security scan units and modules
	@echo "-----------------------"
	@echo "Running TFLint..."
	@tflint --chdir=$(UNITS_DIR) --recursive --config=$(CURDIR)/.tflint.hcl
	@[ -d $(MOD_DIR) ] && tflint --chdir=$(MOD_DIR) --recursive --config=$(CURDIR)/.tflint.hcl || true
	@echo "-----------------------"
	@echo "Scanning for vulnerabilities..."
	@trivy config --severity MEDIUM,HIGH,CRITICAL $(UNITS_DIR)
	@[ -d $(MOD_DIR) ] && trivy config --severity MEDIUM,HIGH,CRITICAL $(MOD_DIR) || true

lint-init: ## Install tflint plugins
	@tflint --init --chdir=$(UNITS_DIR)
	@[ -d $(MOD_DIR) ] && tflint --init --chdir=$(MOD_DIR) || true

# =============================================================================
# PRE-COMMIT
# =============================================================================

prec: ## Run pre-commit on staged files
	@pre-commit run

prec-all: ## Run pre-commit on all files
	@pre-commit run --all-files

# =============================================================================
# UTILITIES
# =============================================================================

units: ## List available units
	@echo "Available units:"
	@ls -1 $(UNITS_DIR)

set-labels: ## Generate Labels in github repo
	$(GITHUB_LABELS)

help: ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
