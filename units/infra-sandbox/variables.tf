variable "github_owner" {
  description = "Github user name"
  type        = string
}

variable "repository_name" {
  description = "Name of the existing github repository"
  type        = string
}

variable "rulesets" {
  type = map(object({
    target_branches         = list(string)
    enforcement             = optional(string, "active")
    required_signatures     = optional(bool, true)
    required_linear_history = optional(bool, false)
    deployment_environments = optional(list(string), [])
    required_checks         = optional(list(string), [])
    require_pull_request = optional(object({
      dismiss_stale_reviews_on_push = optional(bool, false)
      require_last_push_approval    = optional(bool, false)
      required_approvals            = optional(number, 0)
    }), null)
  }))
  default = {}
}
