#!/usr/bin/env bash
set -euo pipefail

echo "🔎 Fetching branches..."
git fetch --all --prune

# Ensure we're on main
git checkout main

# Commit any pending changes to templates/index.json so merge/push won't be blocked
if ! git diff --quiet -- templates/index.json || ! git diff --cached --quiet -- templates/index.json; then
  echo "📝 Committing local Home page changes (templates/index.json)..."
  git add templates/index.json
  git commit -m "Home page updates (index.json)"
fi

# Try to merge the feature branch if it exists (remote or local)
if git show-ref --verify --quiet refs/remotes/origin/feature/barrys-custom; then
  echo "🔀 Merging origin/feature/barrys-custom into main..."
  git merge --no-ff origin/feature/barrys-custom -m "Merge origin/feature/barrys-custom into main"
elif git show-ref --verify --quiet refs/heads/feature/barrys-custom; then
  echo "🔀 Merging local feature/barrys-custom into main..."
  git merge --no-ff feature/barrys-custom -m "Merge feature/barrys-custom into main"
else
  echo "ℹ️ No branch named feature/barrys-custom found. Skipping merge."
fi

echo "🚀 Pushing main to origin..."
git push origin main

echo "✅ Done. In Shopify admin (Theme > GitHub), ensure the connected branch is 'main' and click 'Sync' if it doesn't auto-refresh."
