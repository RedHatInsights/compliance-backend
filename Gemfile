# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 6'
# Use Redis adapter to connect to Sidekiq
gem 'redis', '~> 5.0'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Kafka integration
gem 'racecar', require: false
gem 'rdkafka', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
gem 'rack', '>= 2.1.4'

# Swagger
gem 'rswag-api'
gem 'rswag-ui'

# Database view management
gem 'scenic'

# Config YAML files for all environments
gem 'config'

# APIv1 serializer
gem 'jsonapi-serializer'
# APIv2 serializer
gem 'panko_serializer'

# GraphQL support
gem 'graphql'
gem 'graphql-batch'
gem 'graphql-fragment_cache'

# Pundit authorization system
gem 'pundit'

# Alarms and notifications
gem 'exception_notification'
gem 'slack-notifier'

# Sidekiq - use reliable-fetch by Gitlab
gem 'sidekiq', '< 8'
gem 'gitlab-sidekiq-fetcher', require: 'sidekiq-reliable-fetch'

# Faraday to make requests easier
gem 'faraday'
gem 'faraday-retry'

# Helpers for models, pagination, mass import
gem 'friendly_id', '~> 5.2.4'
gem 'scoped_search'
gem 'will_paginate'
gem 'activerecord-import'
gem 'oj'
gem 'uuid'

# Prometheus exporter
gem 'yabeda'
gem 'yabeda-puma-plugin'
gem 'yabeda-rails'
gem 'yabeda-sidekiq'
gem 'yabeda-prometheus-mmap'

# Nokogiri
gem 'nokogiri', force_ruby_platform: true

# Logging, incl. CloudWatch
gem 'cloudwatchlogger'

# Parsing OpenSCAP reports library
gem 'openscap_parser', '~> 1.6.0'

# RBAC service API
gem 'insights-rbac-api-client', '~> 1.0.1'

# REST API parameter type checking
gem 'stronger_parameters'

# Clowder config
gem 'clowder-common-ruby'

# Support for per request thread-local variables
gem 'request_store'

# Ruby 3 dependencies
gem 'cgi'
gem 'rexml'
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
  gem 'graphiql-rails'
  gem 'bullet'
  gem 'listen', '>= 3.0.5'
  gem 'pry-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
