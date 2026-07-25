#!/usr/bin/env bash
set -euo pipefail

while IFS= read -r directory; do
  echo "==> Validating ${directory}"
  terraform -chdir="${directory}" init -backend=false -input=false -no-color >/dev/null
  terraform -chdir="${directory}" validate -no-color
done < <(./scripts/list-terraform-directories.sh)
