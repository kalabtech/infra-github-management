provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Repository  = title(var.repo_name)
      Environment = title(var.env)
      Project     = title(var.project_name)
    }
  }
}
