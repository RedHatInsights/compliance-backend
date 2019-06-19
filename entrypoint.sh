#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

while ! nc -z redis 6379;
do
  echo "Waiting for redis";
  sleep 1;
done;
echo Ready!;

exec "$@"
