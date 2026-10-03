#!/bin/bash
set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$HOME/Library/Logs/OpenClaw"
LOG_FILE="$LOG_DIR/repo-sync.log"
LOCK_DIR="/tmp/openclaw-repo-sync.lock"

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] sync started"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "sync already running; skipping"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

cd "$REPO_DIR" || exit 1

if [ -n "$(git status --porcelain)" ]; then
  echo "working tree is dirty; refusing to update"
  exit 0
fi

if ! git fetch --quiet origin master; then
  echo "git fetch failed"
  exit 1
fi

LOCAL="$(git rev-parse master)"
REMOTE="$(git rev-parse origin/master)"

if [ "$LOCAL" = "$REMOTE" ]; then
  echo "already up to date"
  exit 0
fi

if git merge-base --is-ancestor "$LOCAL" "$REMOTE"; then
  git merge --ff-only --quiet origin/master
  echo "fast-forwarded to $(git rev-parse --short HEAD)"
else
  echo "local and origin/master diverged; refusing automatic merge"
  exit 0
fi
