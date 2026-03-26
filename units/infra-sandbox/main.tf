module "repo-rulesets" {
  source          = "../../modules/repo-rulesets"
  repository_name = var.repository_name
  rulesets        = var.rulesets
}

module "repo-gha" {
  source               = "../../modules/repo-gha"
  repository_name      = var.repository_name
  environment_creation = var.environment_creation
}
