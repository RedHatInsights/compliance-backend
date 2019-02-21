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

# OpenSCAP dependencies
gem 'openscap'

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
gem 'graphiql-rails'

# Pundit
gem 'pundit'

gem 'exception_notification'
gem 'slack-notifier'

gem 'faraday'
gem 'friendly_id', '~> 5.2.4'
gem 'scoped_search'
gem 'will_paginate'
gem 'prometheus_exporter'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'pry-byebug'
  gem 'pry-remote'
  gem 'shoulda-context'
  gem 'shoulda-matchers'
  gem 'minitest-reporters'
  gem 'mocha'
  gem 'capybara'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'capybara-webkit'
  gem 'codecov', :require => false
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'rubocop', require: false
  gem 'spring'
  gem 'bullet'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
