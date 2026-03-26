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
    target_branch   = string
    required_checks = list(string)
  }))
  default = {}
}
