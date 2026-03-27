variable "github_owner" {
  description = "Github user name"
  type        = string
}

variable "repository_name" {
  description = "Name of the existing github repository"
  type        = string
}

# Variable - Repo Ruleset Module
variable "rulesets" {
  type = map(object({
    target_branches         = list(string)
    enforcement             = optional(string, "active")
    required_signatures     = optional(bool, true)
    required_linear_history = optional(bool, false)
    deployment_environments = optional(list(string), [])

    required_checks = optional(object({
      checks               = optional(list(string), [])
      strict_status_checks = optional(bool, true)
    }), null)

    require_pull_request = optional(object({
      dismiss_stale_reviews_on_push = optional(bool, false)
      require_last_push_approval    = optional(bool, false)
      required_approvals            = optional(number, 0)
      allowed_merge_methods         = optional(list(string), ["squash", "merge", "rebase"])
    }), null)
  }))
  default = {}
}

# Environments
variable "environment_creation" {
  type = map(object({
    prevent_self_review = optional(bool, false)
    wait_timer          = optional(number, 0)
    reviewers           = optional(number, 0)
    branch_policy = optional(object({
      protected_branches = optional(bool, false)
    }), null)
  }))
}

# NOTE: GHA Secrets and Variables
variable "repo_variables" {
  description = "Github Actions general variables"
  type        = map(string)
  default     = {}
}

# NOTE: Not marked as sensitive because Terraform for_each limitation.
# Values are redacted in plan output by the provider.
variable "repo_secrets" {
  description = "Github Actions general secrets"
  type        = map(string)
  default     = {}
}

variable "environment_variables" {
  description = "Github Actions environment variables"
  type        = map(map(string))
  default     = {}
}

# NOTE: Not marked as sensitive because Terraform for_each limitation.
# Values are redacted in plan output by the provider.
variable "environment_secrets" {
  description = "Github Actions environment secrets"
  type        = map(map(string))
  default     = {}
}

# NOTE: labels variables
variable "labels" {
  description = "Github Labels"
  type = map(object({
    color       = optional(string, "cccccc")
    description = optional(string, null)
  }))
  default = {}
}
