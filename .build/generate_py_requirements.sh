#!/usr/bin/env bash
# Run this to update uv lockfile and .pre-commit-config.yaml to latest published
# versions of packages.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "$script_dir/.." && pwd)"

cd "$project_root"

"$project_root/setup_venv.sh"

echo 'Updating uv lockfile...'
uv lock --upgrade

"$project_root/setup_venv.sh"

echo 'Updating pre-commit...'
pre-commit autoupdate
pre-commit gc
pre-commit clean