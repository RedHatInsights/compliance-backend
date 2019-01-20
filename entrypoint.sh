#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

bundle exec rake db:setup

bundle exec rails s -b 0.0.0.0
