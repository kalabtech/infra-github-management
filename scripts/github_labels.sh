#!/usr/bin/env zsh
set -euo pipefail

GITHUB_USER="kalabtech"
REPOS=(
  "infra-github-management"
)

declare -A LABEL_COLORS=(
  ["feature"]="0075ca"
  ["fix"]="d73a4a"
  ["chore"]="e4e669"
  ["refactor"]="c5def5"
  ["docs"]="0075ca"
  ["ci"]="f9d0c4"
  ["release"]="0e8a16"
  ["security"]="b60205"
  ["breaking-change"]="e11d48"
  ["wip"]="cccccc"
)

declare -A LABEL_DESCS=(
  ["feature"]="New feature or enhancement"
  ["fix"]="Bug fix or correction"
  ["chore"]="Maintenance, dependencies, tooling"
  ["refactor"]="Code restructure without behavior change"
  ["docs"]="Documentation only changes"
  ["ci"]="CI/CD pipeline changes"
  ["release"]="Version release"
  ["security"]="Security fix or hardening"
  ["breaking-change"]="Introduces a breaking change"
  ["wip"]="Work in progress, not ready for review"
)

for repo in "${REPOS[@]}"; do
  echo "-> $GITHUB_USER/$repo"
  for label in "${(k)LABEL_COLORS[@]}"; do
    gh label create "$label" \
      --repo "$GITHUB_USER/$repo" \
      --color "${LABEL_COLORS[$label]}" \
      --description "${LABEL_DESCS[$label]}" \
      --force && echo "  check $label" || echo "  x $label (skipped)"
  done
done

echo "Done."
