source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "image_processing", "~> 1.2"
gem "mini_magick"

# Auth & Authorization
gem "devise"
gem "pundit"

# Background jobs & cache
gem "sidekiq", "~> 8.0"
gem "sidekiq-cron"
gem "redis", "~> 5.0"
gem "connection_pool", "~> 2.4"

# Pagination
gem "pagy", "~> 9.0"

# Analytics
gem "blazer"

# ERD visualization
gem "rails-realtime-erd"

# Rate limiting
gem "rack-attack"

# Icons
gem "heroicon"

# HTTP client for external APIs
gem "faraday"
gem "faraday-retry"

# Slugs
gem "friendly_id", "~> 5.5"

# QR codes
gem "rqrcode"

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "faker"
  gem "vcr"
  gem "webmock"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
end
