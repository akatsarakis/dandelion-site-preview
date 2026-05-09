#!/usr/bin/env bash
set -euo pipefail

PREVIEW_REPO="${PREVIEW_REPO:-akatsarakis/dandelion-site-preview}"
PREVIEW_URL="${PREVIEW_URL:-https://antonis.io/dandelion-site-preview/}"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required: https://cli.github.com/"
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required."
  exit 1
fi

root="$(git rev-parse --show-toplevel)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

rsync -a "$root"/ "$tmpdir"/ \
  --exclude '.git' \
  --exclude '.DS_Store' \
  --exclude 'CNAME'

cd "$tmpdir"
git init -q
git checkout -q -b main
git add .
git commit -q -m "Deploy preview from dandelion-site"
git remote add origin "https://github.com/${PREVIEW_REPO}.git"
git push -q -f origin main

if ! gh api "repos/${PREVIEW_REPO}/pages" >/dev/null 2>&1; then
  gh api -X POST "repos/${PREVIEW_REPO}/pages" \
    --input - >/dev/null <<JSON
{"source":{"branch":"main","path":"/"}}
JSON
fi

echo "Preview published: ${PREVIEW_URL}"
