#!/bin/bash

set -euo pipefail

PROJECT_CONFIG="${1:-${PROJECT_CONFIG:-}}"

if [[ -z "$PROJECT_CONFIG" ]]; then
  echo "Usage: $0 config/projects/<project>.env"
  exit 1
fi

if [[ ! -f "$PROJECT_CONFIG" ]]; then
  echo "Project config not found: $PROJECT_CONFIG"
  exit 1
fi

source "$PROJECT_CONFIG"

: "${APP_NAME:?APP_NAME is required}"
: "${SERVER_USER:?SERVER_USER is required}"
: "${SERVER_HOST:?SERVER_HOST is required}"
: "${REMOTE_BACKUP_DIR:?REMOTE_BACKUP_DIR is required}"
: "${LOCAL_BACKUP_ROOT:?LOCAL_BACKUP_ROOT is required}"

LOCAL_BACKUP_DIR="$LOCAL_BACKUP_ROOT/$APP_NAME"
DATE=$(date +%Y-%m-%dT%H%M%S%z)
TARGET_DIR="$LOCAL_BACKUP_DIR/$DATE"

RSYNC_SSH=(ssh)

if [[ -n "${SSH_KEY:-}" ]]; then
  RSYNC_SSH+=( -i "$SSH_KEY" )
fi

# Create a backup directory for today
mkdir -p "$TARGET_DIR"

cleanup_empty_backup_dir() {
  rmdir "$TARGET_DIR" 2>/dev/null || true
}

trap cleanup_empty_backup_dir ERR

# Rsync to fetch database files from the server
rsync -avz \
  -e "${RSYNC_SSH[*]}" \
  --include='*.sqlite3' \
  --include='*.sqlite3-*' \
  --exclude='*' \
  "$SERVER_USER@$SERVER_HOST:$REMOTE_BACKUP_DIR/" \
  "$TARGET_DIR/"

trap - ERR

echo "Backup completed! Files saved to $TARGET_DIR."
