#!/usr/bin/env bash
set -euo pipefail

STRATEGY="theirs"  # conflict preference when merging INTO main: "theirs" = take feature branch version, "ours" = keep main

echo "🔎 Fetching all branches…"
git fetch --all --prune

echo "📦 Ensuring we're on main and up to date…"
git checkout main
git pull --rebase origin main || true

# Commit any in-flight edits (common offender is templates/index.json)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "📝 Committing local changes so merges aren't blocked…"
  git add -A
  git commit -m "WIP before merging feature branches into main"
fi

merge_one () {
  local BR="$1"
  if git show-ref --verify --quiet "refs/remotes/origin/$BR"; then
    echo "🔀 Merging origin/$BR into main (strategy=${STRATEGY})…"
    git merge -m "Merge origin/$BR into main" -X "$STRATEGY" "origin/$BR"
  elif git show-ref --verify --quiet "refs/heads/$BR"; then
    echo "🔀 Merging local $BR into main (strategy=${STRATEGY})…"
    git merge -m "Merge $BR into main" -X "$STRATEGY" "$BR"
  else
    echo "ℹ️ Branch $BR not found; skipping."
  fi
}

merge_one "codex/organize-project-files-into-directories"
merge_one "feature/barrys-custom"

echo "🚀 Pushing main to origin…"
git push origin main

echo "✅ Done."
echo "Next: In Shopify Admin → Online Store → Themes → Connect from GitHub, make sure the connected branch is **main**, then click Sync (if needed)."
