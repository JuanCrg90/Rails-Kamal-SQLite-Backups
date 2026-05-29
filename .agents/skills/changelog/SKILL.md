---
name: changelog
description: Generate or update a repository CHANGELOG.md from recent Git history, working tree diffs, pull requests, or release notes. Use when the user asks to create a changelog, update CHANGELOG.md, summarize last changes, prepare release notes, document recent commits, or add a changelog entry before a PR, release, or merge.
---

# Changelog

## Workflow

1. Inspect existing conventions first.
   - Check for `CHANGELOG.md`, release notes, `package.json`, gemspecs, version files, and prior headings.
   - Preserve the repo's existing changelog format when present.

2. Gather changes from the most relevant source.
   - For local unpublished work: use `git status --short`, `git diff --stat`, and `git diff`.
   - For committed work: use `git log --oneline --decorate` and inspect commits since the last release tag or changelog entry.
   - For GitHub PRs/issues: use `gh` first when available; web only for external references.

3. Choose the range conservatively.
   - If a release tag exists, compare from the latest relevant tag.
   - If no tag exists, summarize recent commits that are not already represented in `CHANGELOG.md`.
   - If the user says "last changes", include current working tree changes plus recent commits only when needed for context.

4. Write concise user-facing entries.
   - Group by common headings when useful: `Added`, `Changed`, `Fixed`, `Removed`, `Security`.
   - Prefer behavior and user impact over implementation details.
   - Mention migrations, breaking changes, config changes, data-loss risk, and manual steps explicitly.
   - Keep entries factual; do not invent issue numbers, PR numbers, versions, or dates.

5. Update or create `CHANGELOG.md`.
   - Create the file when missing.
   - Put newest entries first.
   - Use `## Unreleased` for unreleased local changes unless the user provides a version.
   - Preserve existing historical content below the new entry.

## Output Shape

Use this default when no project convention exists:

```markdown
# Changelog

## Unreleased

### Added

- Added restore workflow for SQLite backups.

### Changed

- Updated backup documentation with restore instructions.
```

Skip empty sections. Keep wording tight.

## Verification

After editing:

- Run relevant format or docs checks if the repo defines them.
- Show `git diff -- CHANGELOG.md`.
- If the changelog is based on assumptions, state the exact range used.
