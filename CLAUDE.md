# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Rails 8.1, Ruby 4.0.5, PostgreSQL, Redis, Sidekiq 7, Hotwire (Turbo + Stimulus), Tailwind CSS 4, Propshaft, importmap (no JS build step).

## Commands

```bash
bin/dev                                        # server + Tailwind watcher (foreman)
bundle exec sidekiq                            # background job worker (required for async jobs)
bundle exec rspec                              # full test suite
bundle exec rspec spec/path/to_spec.rb         # single file
bundle exec rubocop                            # lint
bundle exec rubocop -a                         # auto-fix safe offenses
bundle exec brakeman                           # security scan
bin/rails db:migrate                           # run pending migrations
bin/rails db:seed                              # seed initial data (creates super admin)
```

## Gotchas

- **Migrations before tests**: run `bin/rails db:migrate` in a fresh environment before running specs.
- **Sidekiq must be running**: async jobs (sync, webhooks, rankings) don't execute without `bundle exec sidekiq`.
- **TheSportsDB API key**: sync jobs require a valid `ApiProvider` record with a TheSportsDB API key. Without it, `Sync::ImportFromTsdbJob` and related jobs fail silently.
- **VCR cassettes**: HTTP calls in specs are recorded/replayed via VCR + WebMock. New external API calls need a cassette recorded first.

## Architecture

- **Auth**: Devise. Three roles: `user`, `admin`, `super_admin`.
- **Authorization**: Pundit policies in `app/policies/`. Always call `authorize` in controllers — never skip it.
- **Background jobs**: Sidekiq 7 + sidekiq-cron. Queues: `scheduler > sync > webhooks > default > mailers`.
- **Real-time**: ActionCable + Redis. Channels: `MatchChannel`, `NotificationsChannel`, `RankingChannel`.
- **External APIs**: Adapters in `app/adapters/api_providers/`. Two providers: `TheSportsDbAdapter`, `Worldcup2026Adapter`.
- **i18n**: Default locale `pt-BR`. All user-facing strings use `t()` with keys in `config/locales/pt-BR.yml`. No hardcoded strings in views.

## Code Style

RuboCop with `rubocop-rails-omakase`. A PostToolUse hook auto-runs `rubocop -a` on `.rb` files after every edit. Run `bundle exec rubocop` before committing to catch anything the hook missed.

## Commits

Conventional Commits: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`. Push directly to `main` (no PR workflow).

## Testing

RSpec + Factory Bot + Shoulda Matchers + Capybara (system specs). Factory files in `spec/factories/`. VCR cassettes in `spec/cassettes/`.
