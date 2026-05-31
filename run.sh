#!/bin/bash

set -euo pipefail

git -C /stacks/ pull && git pull && uv run homepi/load.py
