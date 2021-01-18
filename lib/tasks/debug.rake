# frozen_string_literal: true

namespace :db do
  desc 'switch rails logger log level to debug'
  task debug: [:environment] do
    ActiveRecord::Base.logger = Logger.new STDOUT
  end
end
