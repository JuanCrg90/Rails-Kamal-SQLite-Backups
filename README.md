# rails-kamal-sqlite-backups

Reusable SQLite backup scripts for Rails 8 apps deployed with Kamal.

Related write-up: [Backing up SQLite for Rails apps with Kamal](https://juancrg90.me/posts/backing-up-sqlite-rails-kamal/).

Backups are stored inside each app workspace:

```text
~/Projects/<app>-workspace/db_backups/<app>/<timestamp>/
```

Example:

```text
~/Projects/my-app-workspace/db_backups/my-app/2026-05-24T020000-0600/
```

## Setup

Create one project config under `config/projects`.

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

For new apps, copy `config/projects/example.env.example` and update the values.

## Backup

If the project uses a dedicated SSH key, load it first:

```bash
ssh-add ~/.ssh/my-app
```

```bash
./backup.sh config/projects/my-app.env
```

This pulls SQLite files from the Kamal host storage volume into:

```text
$LOCAL_BACKUP_ROOT/$APP_NAME/<timestamp>/
```

## Cleanup

```bash
./cleanup.sh config/projects/my-app.env
```

Cleanup removes timestamped backup directories older than `RETENTION_DAYS`.

## Cron

```cron
0 0 * * * /path/to/rails-kamal-sqlite-backups/backup.sh /path/to/rails-kamal-sqlite-backups/config/projects/my-app.env
0 1 * * * /path/to/rails-kamal-sqlite-backups/cleanup.sh /path/to/rails-kamal-sqlite-backups/config/projects/my-app.env
```

Add one backup and cleanup pair per project.

## Kamal mapping

Project config values usually come from `config/deploy.yml`:

- `SERVER_USER`: `ssh.user`
- `SERVER_HOST`: first app host
- `REMOTE_BACKUP_DIR`: host side of the storage volume, usually `/storage`

For this Kamal volume:

```yaml
volumes:
  - "/storage:/rails/storage"
```

Use:

```bash
REMOTE_BACKUP_DIR=/storage
```
