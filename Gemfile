# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.1'
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Kafka integration
gem 'racecar'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Swagger
gem 'rswag-api'
gem 'rswag-ui'

# Config YAML files for all environments
gem 'config'

# JSON API serializer
gem 'fast_jsonapi'

# GraphQL support
gem 'graphql'

# Pundit
gem 'pundit'

gem 'exception_notification'
gem 'slack-notifier'

# Sidekiq
gem 'sidekiq'

gem 'tty-command'

gem 'attr_encrypted'

gem 'docker-api'

gem 'faraday'
gem 'friendly_id', '~> 5.2.4'
gem 'scoped_search'
gem 'will_paginate'
gem 'prometheus_exporter'

gem 'activerecord-import'
gem 'oj'
gem 'newrelic_rpm'
gem 'gitlab-sidekiq-fetcher', require: 'sidekiq-reliable-fetch'

gem 'openscap_parser', '~> 1.0.0'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'codecov', :require => false
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
