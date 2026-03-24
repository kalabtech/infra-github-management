variable "env" {
  type        = string
  description = "Production environment name"
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Terragrunt project name"
}

variable "repo_name" {
  type        = string
  description = "Target repository name"
}
