source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "propshaft"
gem "webrick"

group :production do
  gem "puma", ">= 5.0"
end

# Database adapters (PostgreSQL for Production & CI, SQLite3 for local dev/testing)
gem "pg", "~> 1.7"
gem "sqlite3", ">= 2.1"

# Hotwire & JS
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Password hashing
gem "bcrypt", "~> 3.1.7"

# Windows zoneinfo
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Solid Cache & Queue
gem "solid_cache"
gem "solid_queue"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
end
