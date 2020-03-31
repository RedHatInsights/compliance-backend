# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

task :log => :environment do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

Rails.application.load_tasks
