# Changelog

## Unreleased

### Added

- Added `restore.sh` to interactively restore a selected local SQLite backup to the configured remote storage directory.
- Added restore safeguards: dry-run mode, typed confirmation, and optional remote safety copy before upload.
- Added a repo-local changelog skill under `.agents/skills/changelog`.

### Changed

- Documented the restore workflow in `README.md` and `docs/how-to-manage-sqlite-backups.md`.
