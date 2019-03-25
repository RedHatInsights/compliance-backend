# frozen_string_literal: true

require 'rake/testtask'

desc 'Run tests and rubocop'
namespace :test do
  task :validate do
    Rake::Task['rubocop'].invoke
    Rake::Task['brakeman'].invoke
    Rake::Task['test'].invoke
    Rake::Task['spec'].invoke
  end
end

task :rubocop do
  require 'rubocop'
  cli = RuboCop::CLI.new
  cli.run(%w[--rails --auto-correct])
end
