# frozen_string_literal: true

require 'simplecov'

if ENV['GITHUB_ACTIONS']
  require 'simplecov-cobertura'
  SimpleCov.command_name 'spec'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start
