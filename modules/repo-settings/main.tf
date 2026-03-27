data "github_repository" "this" {
  name = var.repository_name
}

resource "github_issue_labels" "this" {
  repository = data.github_repository.this.name

  dynamic "label" {
    for_each = var.labels
    iterator = label
    content {
      name        = label.key
      color       = label.value.color
      description = label.value.description
    }
  }
}
