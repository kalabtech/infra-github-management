remote_state {
  backend = "s3"
  config = {
    bucket     = "${get_env("TF_STATE_BUCKET")}"
    key = "${get_env("TF_PROJECT_NAME")}/${path_relative_to_include()}/terraform.tfstate"
    region     = "${get_env("TF_STATE_REGION")}"
    encrypt    = true
    kms_key_id = "${get_env("TF_STATE_KMS")}"
    use_lockfile = true
  }
}

# terragrunt.hcl versions
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.14.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "s3" {}
}
EOF
}
