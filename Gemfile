# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'pg'
gem 'rails', '~> 8.0'
# Use Puma as the app server
gem 'puma', '~> 6'
# Use Redis adapter to connect to Sidekiq
gem 'redis', '~> 4.5'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Kafka integration
gem "karafka", ">= 2.4.0"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack', '>= 2.1.4'
gem 'rack-cors'

# Swagger
gem 'rswag-api'
gem 'rswag-ui'

# Database view, function and trigger management
gem 'fx'
gem 'scenic'

# Config YAML files for all environments
gem 'config'

# APIv1 serializer
gem 'jsonapi-serializer'
# APIv2 serializer
gem 'panko_serializer'

# Pundit authorization system
gem 'pundit'

# Alarms and notifications
gem 'exception_notification'
gem 'slack-notifier'

# Sidekiq - use reliable-fetch by Gitlab
gem 'gitlab-sidekiq-fetcher', require: 'sidekiq-reliable-fetch'
gem 'sidekiq', '< 8'

# Faraday to make requests easier
gem 'faraday'
gem 'faraday-retry'

# Helpers for models, pagination, mass import
gem 'activerecord-import'
gem 'friendly_id', '~> 5.2.4'
gem 'oj'
gem 'toml'
gem 'scoped_search'
gem 'uuid'
gem 'will_paginate'

# Prometheus exporter
gem 'prometheus-client-mmap', '<= 0.28.1'
gem 'yabeda'
gem 'yabeda-prometheus-mmap'
gem 'yabeda-puma-plugin'
gem 'yabeda-rails'
gem 'yabeda-sidekiq'

# Nokogiri
gem 'nokogiri', force_ruby_platform: true

# Logging, incl. CloudWatch
gem 'cloudwatchlogger'

# Parsing OpenSCAP reports library
gem 'openscap_parser', '~> 1.6.0'

# RBAC service API
gem 'insights-rbac-api-client', '~> 2.0.0'

# REST API parameter type checking
gem 'stronger_parameters'

# Clowder config
gem 'clowder-common-ruby'

# Support for per request thread-local variables
gem 'request_store'

# Ruby 3 dependencies
gem 'cgi', '>= 0.4.2'
gem 'rexml'
gem 'time', '>= 0.2.2'
gem 'uri', '>= 0.13.2'
gem 'webrick'

# Allows for tree structures in db
gem 'ancestry'

group :development, :test do
  gem 'awesome_print', require: false
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'irb', '>= 1.2'
  gem 'karafka-testing'
  gem 'rspec'
  gem 'minitest-reporters'
  gem 'minitest-stub-const'
  gem 'mocha'
  gem 'pry-byebug'
  gem 'pry-remote'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'shoulda-context'
  gem 'shoulda-matchers'
  gem 'webmock'
end

group :test do
  gem 'simplecov'
  gem 'simplecov-cobertura'
end

group :development do
  gem 'bullet'
  gem 'listen', '>= 3.0.5'
  gem 'pry-rails'
  gem 'spring'
  gem 'spring-watcher-listen'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
