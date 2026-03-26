module "repo-rulesets" {
  source          = "../../modules/repo-rulesets"
  repository_name = var.repository_name
  rulesets = var.rulesets
}
