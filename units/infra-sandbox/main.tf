module "repo-rulesets" {
  source          = "../../modules/repo-rulesets"
  repository_name = var.repository_name

  rulesets = var.rulesets
}

module "repo-gha" {
  source          = "../../modules/repo-gha"
  repository_name = var.repository_name

  # NOTE: Environment creation inputs
  environment_creation = var.environment_creation

  # NOTE: Variables and secrets inputs
  repo_variables        = var.repo_variables
  repo_secrets          = var.repo_secrets
  environment_variables = var.environment_variables
  environment_secrets   = var.environment_secrets
}

module "repo-settings" {
  source          = "../../modules/repo-settings"
  repository_name = var.repository_name
  labels          = var.labels
}
