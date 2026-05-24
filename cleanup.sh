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
: "${LOCAL_BACKUP_ROOT:?LOCAL_BACKUP_ROOT is required}"
: "${RETENTION_DAYS:=7}"

LOCAL_BACKUP_DIR="$LOCAL_BACKUP_ROOT/$APP_NAME"

if [[ ! -d "$LOCAL_BACKUP_DIR" ]]; then
  echo "Backup directory does not exist: $LOCAL_BACKUP_DIR"
  exit 0
fi

# Find and delete backups older than the retention period
find "$LOCAL_BACKUP_DIR" \
  -mindepth 1 \
  -maxdepth 1 \
  -type d \
  -name '20??-??-??T*' \
  -mtime +"$RETENTION_DAYS" \
  -exec rm -rf {} +

echo "Old backups older than $RETENTION_DAYS days have been deleted from $LOCAL_BACKUP_DIR."
