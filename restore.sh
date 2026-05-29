#!/bin/bash

set -euo pipefail

PROJECT_CONFIG_ARG=""
DRY_RUN=false

usage() {
  echo "Usage: $0 config/projects/<project>.env [--dry-run]"
}

remote_quote() {
  printf "%q" "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$PROJECT_CONFIG_ARG" ]]; then
        usage
        exit 1
      fi

      PROJECT_CONFIG_ARG="$1"
      shift
      ;;
  esac
done

PROJECT_CONFIG="${PROJECT_CONFIG_ARG:-${PROJECT_CONFIG:-}}"

if [[ -z "$PROJECT_CONFIG" ]]; then
  usage
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
CONFIRMATION="RESTORE $APP_NAME"

if [[ ! -d "$LOCAL_BACKUP_DIR" ]]; then
  echo "Backup directory does not exist: $LOCAL_BACKUP_DIR"
  exit 1
fi

mapfile -t BACKUPS < <(
  find "$LOCAL_BACKUP_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -name '20??-??-??T*' \
    -print | sort -r
)

if [[ "${#BACKUPS[@]}" -eq 0 ]]; then
  echo "No backups found in $LOCAL_BACKUP_DIR"
  exit 1
fi

echo "Available backups for $APP_NAME:"

for index in "${!BACKUPS[@]}"; do
  printf "%2d) %s\n" "$((index + 1))" "$(basename "${BACKUPS[$index]}")"
done

read -r -p "Choose backup to restore: " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#BACKUPS[@]} )); then
  echo "Invalid backup selection."
  exit 1
fi

SELECTED_BACKUP="${BACKUPS[$((CHOICE - 1))]}"

if [[ -z "$(find "$SELECTED_BACKUP" -mindepth 1 -maxdepth 1 -type f -print -quit)" ]]; then
  echo "Selected backup has no files: $SELECTED_BACKUP"
  exit 1
fi

SSH_COMMAND=(ssh)

if [[ -n "${SSH_KEY:-}" ]]; then
  SSH_COMMAND+=( -i "$SSH_KEY" )
fi

RSYNC_ARGS=( -avz )

if [[ "$DRY_RUN" == true ]]; then
  RSYNC_ARGS+=( --dry-run )
  echo "Dry run enabled. No files will be uploaded."
fi

echo "Selected backup: $SELECTED_BACKUP"
echo "Remote target: $SERVER_USER@$SERVER_HOST:$REMOTE_BACKUP_DIR/"

if [[ "$DRY_RUN" == false ]]; then
  read -r -p "Create a remote safety copy before restore? [y/N] " SAFETY_COPY

  if [[ "$SAFETY_COPY" =~ ^[Yy]$ ]]; then
    DATE=$(date +%Y-%m-%dT%H%M%S%z)
    REMOTE_SAFETY_DIR="$REMOTE_BACKUP_DIR/pre_restore_$DATE"
    REMOTE_BACKUP_DIR_QUOTED=$(remote_quote "$REMOTE_BACKUP_DIR")
    REMOTE_SAFETY_DIR_QUOTED=$(remote_quote "$REMOTE_SAFETY_DIR")

    echo "Creating remote safety copy at $REMOTE_SAFETY_DIR"

    "${SSH_COMMAND[@]}" "$SERVER_USER@$SERVER_HOST" \
      "mkdir -p $REMOTE_SAFETY_DIR_QUOTED && find $REMOTE_BACKUP_DIR_QUOTED -mindepth 1 -maxdepth 1 -type f \( -name '*.sqlite3' -o -name '*.sqlite3-*' \) -exec cp -p {} $REMOTE_SAFETY_DIR_QUOTED/ \;"
  fi

  echo "This will upload all files from the selected backup to the remote target."
  read -r -p "Type '$CONFIRMATION' to continue: " CONFIRMED

  if [[ "$CONFIRMED" != "$CONFIRMATION" ]]; then
    echo "Restore cancelled."
    exit 1
  fi
fi

rsync "${RSYNC_ARGS[@]}" \
  -e "${SSH_COMMAND[*]}" \
  "$SELECTED_BACKUP/" \
  "$SERVER_USER@$SERVER_HOST:$REMOTE_BACKUP_DIR/"

if [[ "$DRY_RUN" == true ]]; then
  echo "Restore dry run completed."
else
  echo "Restore completed. Restart the app manually when ready."
fi
