# frozen_string_literal: true

require 'rake/testtask'

# https://github.com/presidentbeef/brakeman
desc 'Scan for security vulnerabilities using brakeman'
task :brakeman do
  require 'brakeman/commandline'
  Brakeman::Commandline.start(
    {
      output_files: [
        'brakeman_output.codeclimate',
        'brakeman_output.markdown'
      ]
    },
    Rails.root
  )
end
