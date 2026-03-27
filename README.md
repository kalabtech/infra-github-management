# infra-github-management

> Terraform + Terragrunt project to manage GitHub repository configuration on repos that already exist. <br>
> Each repo has isolated state in S3 - changing one unit has no effect on the rest.

## Features
- Repository settings and feature flags (`repo-settings` module)
- Branch rulesets: push restrictions, PR requirements, status checks, deployment (`repo-ruleset` module)
- GitHub Actions secrets and variables at repo and environment level (`repo-gha` module)
- Deployment environments with wait timers, required reviewers, and branch policies

## Stack
- **IaC:** Terraform + Terragrunt
- **Infrastructure:** GitHub
  - GitHub Provider `integrations/github ~> 6.0` - manages repo config, rulesets, secrets and environments
  - AWS S3 backend - stores Terraform state with KMS encryption per repo
- **CI:** GitHub Actions Terragrunt Checks (Trivy, Gitleaks, Terraform Format and Validate)

## Repository Structure
```
infra-github-management/
├── units/                      # One folder per managed repo (isolated Terragrunt stack)
│   └── <repo-name>/            # terragrunt.hcl + prod.tfvars (gitignored)
├── modules/
│   ├── repo-settings/          # github_repository data source + settings
│   ├── repo-ruleset/           # github_repository_ruleset
│   └── repo-gha/               # environments, secrets and variables
├── scripts/                    # Terraform plan summary scripts for CI/CD
├── docs/                       # ADR
└── root.hcl                    # S3 backend + provider generation
```

## Prerequisites
- Terraform `>= 1.14.0`
- Terragrunt `>= 0.99.4`
- GitHub Provider `integrations/github ~> 6.0`
- Bucket s3 to use backend s3 and fill values in `.env`
- A GitHub token with repo admin scope stored in `.env`:
```bash
  export GITHUB_TOKEN=your_token_here
```
- Copy and fill in your values per repo unit:
  - `units/<repo-name>/prod.tfvars.example` -> `units/<repo-name>/prod.tfvars`

## Usage

Each unit is applied independently. Navigate into the target repo unit and run Terragrunt:
`--var-file=prod.tfvars` set in `root.hcl`

### Without makefile
```bash
cd units/<repo-name>
source ../../.env
terragrunt plan
terragrunt apply
```

### With makefile
```bash
source .env
make init UNIT=/<repo-name>
make plan UNIT=/<repo-name>
make apply UNIT=/<repo-name>
```

## Design Decisions
- **No repository creation**: repos are created manually or via Copier. This project only manages config on existing repos. Using a `data` source instead of `resource` means `terraform destroy` cannot delete the repo itself.
- **Modules are optional**: each module uses `count` or `for_each` with defaults so units only activate what they need.
- **Branch rulesets over branch protection**: `github_branch_protection` is deprecated in provider v6. All branch protection is done with `github_repository_ruleset`.
- **`plaintext_value` for secrets**: GitHub provider cannot read secret values back after creation, so this is the only workable approach. Mitigations and rationale are in `docs/adr/ADR-0001.md`.
- **Isolated tfstate per repo**: each unit has own S3 state key. No shared state, so one repo config cannot affect others.
