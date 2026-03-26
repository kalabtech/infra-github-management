variable "repository_name" {
  description = "Name of the existing github repository"
  type        = string
}

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
