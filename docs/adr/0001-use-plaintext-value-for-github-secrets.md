# ADR-0001: Use `plaintext_value` for GitHub Actions Secrets

**Status:** Accepted
**Date:** 2025-03-27

---

## Context

The GitHub Terraform provider supports two ways to manage secrets: `plaintext_value` and `encrypted_value`. With `encrypted_value`, each secret must be encrypted outside of Terraform using the repository's public key and libsodium before passing it in. This adds external tooling and scripting complexity that this project wants to avoid.

This project manages GitHub Actions secrets through Terraform and Terragrunt, with remote state stored in S3.

## Decision

Use `plaintext_value` for all `github_actions_secret` and `github_actions_environment_secret` resources.

## Consequences

**Positive**
- No external encryption tooling or scripts needed.
- The provider marks `plaintext_value` as sensitive, so values are redacted in plan output and logs.
- Consumers pass plain `map(string)` variables — no extra wrapping or transformation.

**Negative**
- Secret values are stored in plain text in the Terraform state file.

**Mitigations**
- State is stored in S3 with SSE-KMS enabled.
- Bucket access is restricted via IAM policies following least privilege.
- Secret values are passed via `.tfvars` files excluded from version control via `.gitignore`.
- No outputs expose secret values.

## Alternatives Considered

**`encrypted_value`** — This approach requires encrypting each secret outside of Terraform using libsodium, which means adding tooling and scripts just to feed values into the provider. Given that state is already protected with KMS and access-restricted S3, the extra complexity is not worth it.
