data "github_repository" "this" {
  name = var.repository_name
}

resource "github_repository_ruleset" "main" {
  count = var.protect_main ? 1 : 0

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

    required_deployments {
      required_deployment_environments = ["prod"]
    }

    required_status_checks {
      required_check {
        context = "terraform checks"
      }
    }
  }
}

resource "github_repository_ruleset" "dev" {
  count = var.protect_dev ? 1 : 0

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

    required_deployments {
      required_deployment_environments = ["dev"]
    }

    required_status_checks {
      required_check {
        context = "terraform checks"
      }
    }
  }
}
