# syntax=docker/dockerfile:1

# ── Stage 1: instala gems ─────────────────────────────────────────────────────
FROM ruby:4.0.5-slim AS gems

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libyaml-dev pkg-config curl && \
    rm -rf /var/lib/apt/lists/*

# BUNDLE_PATH garante que bundle install e o stage de runtime usem o mesmo dir.
# BUNDLE_WITHOUT evita instalar gems de dev/test.
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    bundle exec bootsnap precompile --gemfile

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM ruby:4.0.5-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq5 imagemagick curl fonts-liberation && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

WORKDIR /app

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --chown=rails:rails . .

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

RUN bundle exec bootsnap precompile app/ lib/

# Compila Tailwind CSS + fingerprinta assets no build (não em runtime).
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

USER 1000:1000

EXPOSE 3000

ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
