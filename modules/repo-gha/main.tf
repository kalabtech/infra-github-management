data "github_repository" "this" {
  name = var.repository_name
}

resource "github_repository_environment" "example" {
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
