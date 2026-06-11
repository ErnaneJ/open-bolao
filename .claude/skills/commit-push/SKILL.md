---
name: commit-push
description: Stage changed files, write a Conventional Commits message, commit, and push to main. Only the user can invoke this.
disable-model-invocation: true
---

Arguments: $ARGUMENTS (optional hint for the commit message or scope)

Steps:
1. Run `git status` to see changed files.
2. Run `git diff` to understand what changed.
3. Stage files with `git add <specific files>` — never `git add -A` or `git add .`.
4. Draft a Conventional Commits message: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`. Focus on the WHY. Keep it under 72 chars.
5. Show the proposed message and staged files to the user and wait for confirmation.
6. After confirmation: commit using HEREDOC format, then `git push origin main`.

Never use `--no-verify`. Never force push.
