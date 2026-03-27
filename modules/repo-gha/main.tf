data "github_repository" "this" {
  name = var.repository_name
}

# Github Actions Variables and Secrets locals
# NOTE: Convert map(map(string)) into map(object) with merge() to be able to use for_each
locals {
  environment_variables = merge([
    for env, variables in var.environment_variables : {
      for name, value in variables : "${env}-${name}" => {
        environment = env
        name        = name
        value       = value
      }
    }
  ]...)

  environment_secrets = merge([
    for env, secrets in var.environment_secrets : {
      for name, value in secrets : "${env}-${name}" => {
        environment = env
        name        = name
        value       = value
      }
    }
  ]...)
}

# NOTE: Create environments
resource "github_repository_environment" "this" {
  for_each = var.environment_creation != null ? var.environment_creation : {}

  environment         = each.key
  repository          = data.github_repository.this.name
  wait_timer          = each.value.wait_timer
  prevent_self_review = each.value.prevent_self_review

  dynamic "reviewers" {
    for_each = each.value.reviewers > 0 ? [1] : []
    content {
      users = each.value.reviewers
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.branch_policy != null ? [1] : []
    content {
      protected_branches     = each.value.branch_policy.protected_branches
      custom_branch_policies = false
    }
  }
}

# NOTE: Set GHA Variables and Secrets
resource "github_actions_variable" "repo" {
  for_each = var.repo_variables

  repository    = var.repository_name
  variable_name = each.key
  value         = each.value
}

# NOTE: See ADR-0001 for plaintext_value reasoning
#trivy:ignore:AVD-GIT-0002
resource "github_actions_secret" "repo" {
  for_each = var.repo_secrets

  repository      = var.repository_name
  secret_name     = each.key
  plaintext_value = each.value
}

resource "github_actions_environment_variable" "this" {
  for_each = local.environment_variables

  repository    = var.repository_name
  environment   = github_repository_environment.this[each.value.environment].environment
  variable_name = each.value.name
  value         = each.value.value
}

# NOTE: See ADR-0001 for plaintext_value reasoning
#trivy:ignore:AVD-GIT-0002
resource "github_actions_environment_secret" "this" {
  for_each = local.environment_secrets

  repository      = var.repository_name
  environment     = github_repository_environment.this[each.value.environment].environment
  secret_name     = each.value.name
  plaintext_value = each.value.value
}
