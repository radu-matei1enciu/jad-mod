#!/usr/bin/env bash
set -euo pipefail

echo "Destroying Terraform infrastructure..."

terraform -chdir=infra destroy -auto-approve

echo "Destroyed demo infrastructure."
