data "github_repository" "this" {
  name = var.repository_name
}

resource "github_repository_ruleset" "this" {
  for_each = data.github_repository.this.visibility == "public" ? var.rulesets : {}

  name        = each.key
  repository  = data.github_repository.this.name
  target      = "branch"
  enforcement = each.value.enforcement

  conditions {
    ref_name {
      include = [for b in each.value.target_branches : "refs/heads/${b}"]
      exclude = []
    }
  }

  rules {
    creation                = true
    deletion                = true
    required_linear_history = each.value.required_linear_history
    required_signatures     = each.value.required_signatures
    non_fast_forward        = true

    dynamic "pull_request" {
      for_each = each.value.require_pull_request == null ? [] : [1]
      content {
        required_approving_review_count = each.value.require_pull_request.required_approvals
        dismiss_stale_reviews_on_push   = each.value.require_pull_request.dismiss_stale_reviews_on_push
        require_last_push_approval      = each.value.require_pull_request.require_last_push_approval
      }
    }

    dynamic "required_deployments" {
      for_each = length(each.value.deployment_environments) > 0 ? [1] : []
      content {
        required_deployment_environments = each.value.deployment_environments
      }
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.required_checks) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = each.value.required_checks
          iterator = check
          content {
            context        = check.value
            integration_id = 15368
          }
        }
      }
    }
  }
}
