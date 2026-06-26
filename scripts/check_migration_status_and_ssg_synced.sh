#!/usr/bin/bash

MAX_INIT_TIMEOUT_SECONDS=${MAX_INIT_TIMEOUT_SECONDS:-120}

for ((i=1;i<=MAX_INIT_TIMEOUT_SECONDS;i++)); do
    echo "=== Loop iteration $i ==="
    
    echo "START db:debug"
    bundle exec rake --trace db:debug
    DB_DEBUG_EXIT=$?
    echo "DONE db:debug (exit $DB_DEBUG_EXIT)"
    
    echo "START db:migrate"
    bundle exec rake --trace db:migrate
    DB_MIGRATE_EXIT=$?
    echo "DONE db:migrate (exit $DB_MIGRATE_EXIT)"

    if [ $DB_MIGRATE_EXIT -eq 0 ]; then
        echo "START ssg:check_synced"
        bundle exec rake --trace ssg:check_synced
        SSG_EXIT=$?
        echo "DONE ssg:check_synced (exit $SSG_EXIT)"
        
        if [ $SSG_EXIT -eq 0 ]; then
            echo "All init tasks succeeded. Exiting."
            exit 0
        fi
    fi

    echo "Tasks not fully synced/ready. Sleeping 1 second..."
    sleep 1
done

echo "MAX_INIT_TIMEOUT_SECONDS reached. Exiting 1."
exit 1
