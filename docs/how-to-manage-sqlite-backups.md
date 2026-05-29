# How to manage SQLite database backups

`rails-kamal-sqlite-backups` keeps one reusable backup flow for Rails 8 apps deployed with Kamal.
Each app gets a small config file, and backups stay inside that app's workspace.

## Directory pattern

Use this shape for every project:

```text
~/Projects/<app>-workspace/
  <app>/
  db_backups/
    <app>/
      2026-05-24T020000-0600/
        production.sqlite3
        production.sqlite3-wal
        production.sqlite3-shm
```

Examples:

```text
~/Projects/my-app-workspace/db_backups/my-app/
~/Projects/another-app-workspace/db_backups/another-app/
```

## Project config

Create one config file per app under `config/projects`.

```bash
APP_NAME=my-app
WORKSPACE_DIR=~/Projects/my-app-workspace
LOCAL_BACKUP_ROOT="$WORKSPACE_DIR/db_backups"

SERVER_USER=deployer
SERVER_HOST=example.com
REMOTE_BACKUP_DIR=/storage
SSH_KEY=~/.ssh/my-app

RETENTION_DAYS=7
```

## Backup

If the project uses a dedicated SSH key, load it first:

```bash
ssh-add ~/.ssh/my-app
```

Run:

```bash
./backup.sh config/projects/my-app.env
```

The script pulls SQLite files from the Kamal host storage volume and writes them
to:

```text
$LOCAL_BACKUP_ROOT/$APP_NAME/<timestamp>/
```

For this example, that resolves to:

```text
~/Projects/my-app-workspace/db_backups/my-app/<timestamp>/
```

## Cleanup

Run:

```bash
./cleanup.sh config/projects/my-app.env
```

Cleanup only removes timestamped backup directories directly under:

```text
$LOCAL_BACKUP_ROOT/$APP_NAME
```

It keeps the latest 7 days by default through `RETENTION_DAYS=7`.

## Restore

Preview the upload without changing the server:

```bash
./restore.sh config/projects/my-app.env --dry-run
```

Run the restore:

```bash
./restore.sh config/projects/my-app.env
```

The script lists timestamped backup directories from newest to oldest under:

```text
$LOCAL_BACKUP_ROOT/$APP_NAME
```

Pick the backup version to restore. The script uploads all files from that
timestamped directory to:

```text
$SERVER_USER@$SERVER_HOST:$REMOTE_BACKUP_DIR/
```

Before upload, the script can create a remote safety copy of existing SQLite
files at:

```text
$REMOTE_BACKUP_DIR/pre_restore_<timestamp>/
```

Restore requires typing `RESTORE <app-name>` before any upload. It does not
restart the app; restart manually after the files are in place.

## Cron

Example daily schedule:

```cron
0 0 * * * /path/to/rails-kamal-sqlite-backups/backup.sh /path/to/rails-kamal-sqlite-backups/config/projects/my-app.env
0 1 * * * /path/to/rails-kamal-sqlite-backups/cleanup.sh /path/to/rails-kamal-sqlite-backups/config/projects/my-app.env
```

Add one pair per app.

## Kamal mapping

For Rails 8 SQLite apps using Kamal, these values usually come from
`config/deploy.yml`:

- `SERVER_USER`: `ssh.user`
- `SERVER_HOST`: first host under `servers`
- `REMOTE_BACKUP_DIR`: host side of the persistent volume, usually `/storage`
- `SSH_KEY`: local private key for that app, when not using the default SSH key

Example Kamal volume:

```yaml
volumes:
  - "/storage:/rails/storage"
```

In that case, keep `REMOTE_BACKUP_DIR=/storage`.
