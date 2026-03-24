# =============================================================================
# MAKEFILE - infra-core (multi-stack with Terragrunt)
#
# Usage:
#   make plan STACK=unit-name          -> plan a single stack
#   make plan-all                -> plan all stacks
#   make apply STACK=unit-name         -> apply a single stack
#   make resources STACK=shared  -> list resources in a stack
# =============================================================================

# --- VARIABLES ---
STACKS_DIR  = ./stacks
MOD_DIR     = ./modules
STACK       ?=
STACK_PATH  = $(STACKS_DIR)/$(STACK)
PLAN_FILE = terraform.tfplan
ALL_STACKS  = $(wildcard $(STACKS_DIR)/*)

# --- GUARDS ---
# Require STACK parameter
require-stack:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK is required. Usage: make <target> STACK=<name>"; \
		echo "Available stacks:"; \
		ls -1 $(STACKS_DIR); \
		exit 1; \
	fi
	@if [ ! -d "$(STACK_PATH)" ]; then \
		echo "Error: stack '$(STACK)' not found in $(STACKS_DIR)/"; \
		echo "Available stacks:"; \
		ls -1 $(STACKS_DIR); \
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
	@./scripts/tf-plan-summary.sh $(STACK_PATH)/$(PLAN_FILE)
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
        require-stack require-env stacks set-labels help

# =============================================================================
# SINGLE STACK COMMANDS - require STACK=<name>
# =============================================================================

init: require-stack require-env ## Initialize a stack - make init STACK=unit-name
	$(AWS_IDENTITY)
	@echo "Initializing $(STACK)..."
	@cd $(STACK_PATH) && terragrunt init

plan: require-stack ## Plan a stack - make plan STACK=unit-name
	$(AWS_IDENTITY)
	@echo "Planning $(STACK)..."
	@cd $(STACK_PATH) && terragrunt plan -out=$(PLAN_FILE)
	$(TFPLAN_SUMMARY)

apply: require-stack ## Apply a stack - make apply STACK=unit-name
	$(AWS_IDENTITY)
	@echo "Applying $(STACK)..."
	@cd $(STACK_PATH) && terragrunt apply $(PLAN_FILE)

destroy: require-stack ## Destroy a stack - make destroy STACK=unit-name
	$(AWS_IDENTITY)
	@echo "WARNING: Destroying $(STACK)"
	@cd $(STACK_PATH) && terragrunt destroy

resources: require-stack ## List resources - make resources STACK=unit-name
	$(AWS_IDENTITY)
	@cd $(STACK_PATH) && terragrunt state list

show: require-stack ## Show a resource - make show STACK=unit-name RES=aws_iam_policy.x
	$(AWS_IDENTITY)
	@cd $(STACK_PATH) && terragrunt state show $(RES)

state: require-stack ## Pull state - make state STACK=unit-name
	$(AWS_IDENTITY)
	@cd $(STACK_PATH) && terragrunt state pull

output: require-stack ## Show outputs - make output STACK=unit-name
	$(AWS_IDENTITY)
	@cd $(STACK_PATH) && terragrunt output -json | jq '.'

# =============================================================================
# ALL STACKS COMMANDS - uses terragrunt run-all (resolves dependencies)
# =============================================================================

init-all: require-env ## Initialize all stacks
	$(AWS_IDENTITY)
	@cd $(STACKS_DIR) && terragrunt run-all init

plan-all: ## Plan all stacks
	$(AWS_IDENTITY)
	@cd $(STACKS_DIR) && terragrunt run-all plan

apply-all: ## Apply all stacks
	$(AWS_IDENTITY)
	@echo "WARNING: Applying ALL stacks"
	@cd $(STACKS_DIR) && terragrunt run-all apply

# =============================================================================
# QUALITY AND SECURITY
# =============================================================================

format: require-stack ## Format and validate - make check STACK=unit-name
	@echo "Formatting..."
	@terraform fmt -recursive $(STACKS_DIR)
	@terraform fmt -recursive $(MOD_DIR)
	@echo "-----------------------"
	@echo "Validating $(STACK)..."
	@cd $(STACK_PATH) && terragrunt validate

check: ## Security scan stacks and modules
	@echo "-----------------------"
	@echo "Running TFLint..."
	@tflint --chdir=$(STACKS_DIR) --recursive --config=$(CURDIR)/.tflint.hcl
	@[ -d $(MOD_DIR) ] && tflint --chdir=$(MOD_DIR) --recursive --config=$(CURDIR)/.tflint.hcl || true
	@echo "-----------------------"
	@echo "Scanning for vulnerabilities..."
	@trivy config --severity MEDIUM,HIGH,CRITICAL $(STACKS_DIR)
	@[ -d $(MOD_DIR) ] && trivy config --severity MEDIUM,HIGH,CRITICAL $(MOD_DIR) || true

lint-init: ## Install tflint plugins
	@tflint --init --chdir=$(STACKS_DIR)
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

stacks: ## List available stacks
	@echo "Available stacks:"
	@ls -1 $(STACKS_DIR)

set-labels: ## Generate Labels in github repo
	$(GITHUB_LABELS)

help: ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
