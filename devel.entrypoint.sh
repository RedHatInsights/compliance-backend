#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /opt/app-root/src/tmp/pids/server.pid

exec "$@"
