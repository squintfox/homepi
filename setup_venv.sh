#!/usr/bin/env bash
# This can be run to set up your local machine with all requirements (or update them)

echo ""
echo "Please wait, installing/upgrading environment... (this may take a few minutes)"
echo ""

# remove any existing venv to ensure a clean install
if [[ -n "$VIRTUAL_ENV" ]]; then
  deactivate
fi
rm -rf venv

# install/upgrade uv (assumes Linux/macOS; for Windows use winget)
curl -LsSf https://astral.sh/uv/install.sh | sh

# shell completion for uv and uvx (bash)
PROFILE_FILE="$HOME/.bashrc"
if [[ ! -f "$PROFILE_FILE" ]]; then
  touch "$PROFILE_FILE"
fi
COMPLETION_LINE='eval "$(uv generate-shell-completion bash)"'
grep -qxF "$COMPLETION_LINE" "$PROFILE_FILE" || echo "$COMPLETION_LINE" >> "$PROFILE_FILE"
COMPLETION_LINE_UVX='eval "$(uvx --generate-shell-completion bash)"'
grep -qxF "$COMPLETION_LINE_UVX" "$PROFILE_FILE" || echo "$COMPLETION_LINE_UVX" >> "$PROFILE_FILE"

# create venv if it doesn't exist
if [[ ! -d ".venv" ]]; then
  uv venv
fi
# activate venv
source .venv/bin/activate

# UNCOMMENT to upgrade lockfile/deps
# uv lock --upgrade
# pre-commit autoupdate

uv sync --all-groups

# install local pre-commit hooks
pre-commit install

echo ""
echo "Completed environment setup."
echo ""
