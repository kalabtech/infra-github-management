variable "repository_name" {
  description = "Name of the existing github repository"
  type        = string
}

# NOTE: Environments
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
