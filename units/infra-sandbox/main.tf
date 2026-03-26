module "infra-sanbox" {
  source          = "../../modules/repo-rulesets"
  repository_name = var.repository_name

  rulesets = var.rulesets
}
