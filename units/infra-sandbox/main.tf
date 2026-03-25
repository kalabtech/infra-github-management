module "isa" {
  source          = "../../modules/repo-settings"
  repository_name = var.repository_name

  protect_dev  = var.protect_dev
  protect_main = var.protect_main

  required_checks = var.required_checks
}
