#!/bin/bash

set -e

if [ -z "$APPLICATION_TYPE" ]; then
  echo "APPLICATION_TYPE not defined!"
  exit 1
fi

if [ "$APPLICATION_TYPE" = "compliance-backend" ]; then
  exec bundle exec puma
elif [ "$APPLICATION_TYPE" = "compliance-inventory" ]; then
  exec bundle exec racecar InventoryEventsConsumer
elif [ "$APPLICATION_TYPE" = "compliance-sidekiq" ]; then
  exec bundle exec sidekiq
elif [ "$APPLICATION_TYPE" = "compliance-import-remediations" ]; then
  exec bundle exec rake import_remediations --trace
elif [ "$APPLICATION_TYPE" = "compliance-import-ssg" ]; then
  exec bundle exec rake ssg:import_rhel_supported --trace
elif [ "$APPLICATION_TYPE" = "sleep" ]; then
  while true; do sleep 60; done
else
  echo "Application type '$APPLICATION_TYPE' not supported"
fi
