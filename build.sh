#!/usr/bin/env bash
# Cloudflare Pages build command. Output directory: site
set -euo pipefail

pip install -r requirements.txt
mkdocs build
