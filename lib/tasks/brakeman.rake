# frozen_string_literal: true

require 'rake/testtask'

# https://github.com/presidentbeef/brakeman
desc 'Scan for security vulnerabilities using brakeman'
task brakeman: :environment do
  require 'brakeman/commandline'
  Brakeman::Commandline.start(
    {
      print_report: true,
      skip_files: ['bundle/']
    },
    Rails.root
  )
end
