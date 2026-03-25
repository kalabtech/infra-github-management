data "github_repository" "this" {
  name = var.repository_name
}

resource "github_repository_ruleset" "main" {
  count = var.protect_main && data.github_repository.this.visibility == "public" ? 1 : 0

  name        = "main"
  repository  = data.github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    creation                = true
    deletion                = true
    required_linear_history = true
    required_signatures     = true

    dynamic "required_status_checks" {
      for_each = length(var.required_checks) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = var.required_checks
          content {
            context        = required_check.value
            integration_id = 15368
          }
        }
      }
    }
  }
}

resource "github_repository_ruleset" "dev" {
  count = var.protect_dev && data.github_repository.this.visibility == "public" ? 1 : 0

  name        = "dev"
  repository  = data.github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/dev"]
      exclude = []
    }
  }

  rules {
    creation                = true
    deletion                = true
    required_linear_history = true
    required_signatures     = true

    dynamic "required_status_checks" {
      for_each = length(var.required_checks) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = var.required_checks
          content {
            context        = required_check.value
            integration_id = 15368
          }
        }
      }
    }
  }
}
