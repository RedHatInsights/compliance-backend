# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4'
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 4'
# Use Redis adapter to connect to Sidekiq
gem 'redis', '~> 4.0'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Kafka integration
gem 'racecar'
gem 'ruby-kafka'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
gem 'rack', '>= 2.1.4'

# Swagger
gem 'rswag-api'
gem 'rswag-ui'

# Config YAML files for all environments
gem 'config'

# JSON API serializer
gem 'fast_jsonapi'

# GraphQL support
gem 'graphql'
gem 'graphql-batch'

# Pundit authorization system
gem 'pundit'

# Alarms and notifications
gem 'exception_notification'
gem 'slack-notifier'

# Sidekiq - use reliable-fetch by Gitlab
gem 'sidekiq'
gem 'gitlab-sidekiq-fetcher', require: 'sidekiq-reliable-fetch'

# Faraday to make requests easier
gem 'faraday'

# Helpers for models, pagination, mass import
gem 'friendly_id', '~> 5.2.4'
gem 'scoped_search'
gem 'will_paginate'
gem 'activerecord-import' # Substitute on upgrade to Rails 6
gem 'oj'
gem 'uuid'

# Prometheus exporter
gem 'prometheus_exporter', '>= 0.5'

# Logging, incl. CloudWatch
gem 'manageiq-loggers', '~> 0.6.0'

# Parsing OpenSCAP reports library
gem 'openscap_parser', '~> 1.0.0'

# REST API parameter type checking
gem 'stronger_parameters'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'codecov', :require => false
  gem 'simplecov', '~> 0.17.0'
  gem 'minitest-reporters'
  gem 'mocha'
  gem 'pry-byebug'
  gem 'pry-remote'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'shoulda-context'
  gem 'shoulda-matchers'
  gem 'dotenv-rails'
  gem 'irb', '>= 1.2'
  gem 'silent_stream'
  gem 'webmock'
end

group :development do
  gem 'graphiql-rails'
  gem 'bullet'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'pry-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  # load local gemfile
  local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local')
  self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
end
