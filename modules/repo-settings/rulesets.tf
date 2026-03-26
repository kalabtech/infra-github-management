data "github_repository" "this" {
  name = var.repository_name
}

resource "github_repository_ruleset" "this" {
  for_each = data.github_repository.this.visibility == "public" ? var.rulesets : {}

  name        = each.key
  repository  = data.github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/${each.value.target_branch}"]
      exclude = []
    }
  }

  rules {
    creation                = true
    deletion                = true
    required_linear_history = true
    required_signatures     = true

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
