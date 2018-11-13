# frozen_string_literal: true

desc 'Run tests and rubocop'
task :validate do
  Rake::Task['rubocop'].invoke
  Rake::Task['test'].invoke
  Rake::Task['spec'].invoke
end

task :rubocop do
  require 'rubocop'
  cli = RuboCop::CLI.new
  cli.run(%w[--rails --auto-correct])
end
