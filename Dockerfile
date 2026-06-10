# syntax=docker/dockerfile:1

# Stage 1: assets (Node.js para Tailwind build)
FROM node:20-slim AS assets
WORKDIR /app
COPY package*.json ./
RUN npm ci --if-present || true
COPY . .
# Tailwind é gerenciado pela gem, não pelo npm — apenas copiamos os assets
RUN mkdir -p public/assets

# Stage 2: gems (Ruby build environment)
FROM ruby:3.3-slim AS gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libyaml-dev pkg-config \
      libvips curl && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    bundle exec bootsnap precompile --gemfile

# Stage 3: final runtime
FROM ruby:3.3-slim AS runtime

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq5 libvips curl imagemagick && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

WORKDIR /app

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --chown=rails:rails . .

RUN bundle exec bootsnap precompile app/ lib/

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    BUNDLE_PATH=/usr/local/bundle

USER 1000:1000

EXPOSE 3000

ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
