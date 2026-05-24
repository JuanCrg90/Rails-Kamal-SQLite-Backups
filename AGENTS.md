# AGENTS.md

Keep replies short, direct, and action-first.

## Purpose

`rails-kamal-sqlite-backups` manages reusable SQLite backup scripts for Rails 8
apps deployed with Kamal.

Backups should live inside each app workspace:

```text
~/Projects/<app>-workspace/db_backups/<app>/<timestamp>/
```

Do not reintroduce a global backup root like:

```text
~/backups
```

## Project Configs

Each app gets one config file under `config/projects`.

Required values:

```bash
APP_NAME=<app>
WORKSPACE_DIR=~/Projects/<app>-workspace
LOCAL_BACKUP_ROOT="$WORKSPACE_DIR/db_backups"

SERVER_USER=deployer
SERVER_HOST=<host>
REMOTE_BACKUP_DIR=/storage
# Optional project-specific deploy key.
# SSH_KEY=~/.ssh/<app>

RETENTION_DAYS=7
```

For future apps, copy `config/projects/example.env.example` and update values.

## Scripts

- `backup.sh`: fetches SQLite files from the remote Kamal storage volume.
- `cleanup.sh`: removes old timestamped backup directories.

Keep scripts POSIX-ish Bash, small, and readable. Prefer explicit validation for
required config values.

## Safety

- Never run `backup.sh` against production unless the user explicitly asks.
- If SSH fails with `Permission denied (publickey)`, check whether the app key
  needs `ssh-add ~/.ssh/<app>`.
- Never delete backup directories outside `$LOCAL_BACKUP_ROOT/$APP_NAME`.
- Cleanup must use `mindepth 1`, `maxdepth 1`, and timestamp-pattern matching.
- Avoid destructive commands. Use `trash` when deleting local files manually.
- Do not paste secrets from `.kamal/secrets`, credentials, or environment files.

## Verification

Before handoff:

```bash
bash -n backup.sh
bash -n cleanup.sh
```

If script behavior changes, update:

- `README.md`
- `docs/how-to-manage-sqlite-backups.md`

## Git

- Check `git status --short` before edits.
- Keep changes scoped.
- Commit messages, when requested, use Conventional Commits.
