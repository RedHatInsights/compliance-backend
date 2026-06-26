#!/usr/bin/bash

MAX_INIT_TIMEOUT_SECONDS=${MAX_INIT_TIMEOUT_SECONDS:-120}

# Fetch the container name or hostname so we know who is logging
POD_ID=$(hostname)

log_time() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S.%3N')][$POD_ID] $1"
}

for ((i=1;i<=MAX_INIT_TIMEOUT_SECONDS;i++)); do
    log_time "=== Loop iteration $i ==="
    
    log_time "START db:debug"
    bundle exec rake --trace db:debug
    DB_DEBUG_EXIT=$?
    log_time "DONE db:debug (exit $DB_DEBUG_EXIT)"
    
    log_time "START db:migrate"
    bundle exec rake --trace db:migrate
    DB_MIGRATE_EXIT=$?
    log_time "DONE db:migrate (exit $DB_MIGRATE_EXIT)"

    if [ $DB_MIGRATE_EXIT -eq 0 ]; then
        log_time "START ssg:check_synced"
        bundle exec rake --trace ssg:check_synced
        SSG_EXIT=$?
        log_time "DONE ssg:check_synced (exit $SSG_EXIT)"
        
        if [ $SSG_EXIT -eq 0 ]; then
            log_time "All init tasks succeeded. Exiting."
            exit 0
        fi
    fi

    log_time "Tasks not fully synced/ready. Sleeping 1 second..."
    sleep 1
done

log_time "MAX_INIT_TIMEOUT_SECONDS reached. Exiting 1."
exit 1
