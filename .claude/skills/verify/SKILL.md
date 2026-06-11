---
name: verify
description: Run RSpec and RuboCop on changed files to verify correctness before committing.
---

Run the following checks and report results:

1. Run `git diff --name-only HEAD` to identify changed Ruby files.
2. Run `bundle exec rubocop` — list any remaining offenses (the auto-correct hook handles safe ones).
3. Find spec files that correspond to changed files (e.g., `app/models/pool.rb` → `spec/models/pool_spec.rb`).
4. Run `bundle exec rspec <relevant_spec_files>` — or `bundle exec rspec` if you want the full suite.
5. Report pass/fail counts; for failures, show file:line and the error message.

If all checks pass, confirm it's ready to commit.
If any fail, describe what needs fixing before the commit.
