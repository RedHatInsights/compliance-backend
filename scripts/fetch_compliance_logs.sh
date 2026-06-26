#!/usr/bin/env bash

# Exit on error
set -e

# Ensure we are logged into oc and have a project selected
if ! oc project &>/dev/null; then
    echo "Error: Not logged into OpenShift or no project selected."
    echo "Please run 'oc login' and 'oc project <project>' first."
    exit 1
fi

CURRENT_PROJECT=$(oc project -q)
echo "Current project: $CURRENT_PROJECT"

# Ask user for source/context
read -p "Enter source/context for these logs (e.g., jenkins, local-bonfire, no-sidekiq): " SOURCE
if [[ -z "$SOURCE" ]]; then
    SOURCE="unknown"
fi

# Create directory
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUT_DIR="$HOME/tmp/compliance-logs/${TIMESTAMP}-${SOURCE}"
mkdir -p "$OUT_DIR"
echo "Saving logs to: $OUT_DIR"

# Find all compliance pods
PODS=$(oc get pods -n "$CURRENT_PROJECT" -o name | grep "compliance")

if [[ -z "$PODS" ]]; then
    echo "No compliance pods found in project $CURRENT_PROJECT"
    exit 0
fi

for POD in $PODS; do
    POD_NAME=${POD#pod/}
    echo "Fetching logs for pod: $POD_NAME"

    # Get all containers in the pod (init containers + regular containers)
    CONTAINERS=$(oc get pod "$POD_NAME" -n "$CURRENT_PROJECT" -o jsonpath='{range .spec.initContainers[*]}{.name}{"\n"}{end}{range .spec.containers[*]}{.name}{"\n"}{end}')

    for CONTAINER in $CONTAINERS; do
        LOG_FILE="$OUT_DIR/${POD_NAME}_${CONTAINER}.log"
        echo "  -> Container: $CONTAINER"
        
        # Try fetching logs. If container hasn't started yet, oc logs might fail, so we ignore errors
        oc logs "$POD_NAME" -c "$CONTAINER" -n "$CURRENT_PROJECT" > "$LOG_FILE" 2>/dev/null || echo "     (No logs available or container not started)"
        
        # Also grab previous logs if container restarted
        PREV_LOG_FILE="$OUT_DIR/${POD_NAME}_${CONTAINER}_previous.log"
        oc logs "$POD_NAME" -c "$CONTAINER" -n "$CURRENT_PROJECT" --previous > "$PREV_LOG_FILE" 2>/dev/null || rm -f "$PREV_LOG_FILE"
    done
done

echo ""
echo "Done! All logs saved to $OUT_DIR"

TIMELINE_FILE="$OUT_DIR/00-merged-timeline.txt"
echo "Creating merged timeline of init events..."
# Extract our custom bash timestamp lines, which start with [2026- (or current year)
# -h hides the filename prefix from grep so sort works strictly on the timestamp
grep -h "^\[$(date +'%Y')" "$OUT_DIR"/*init.log | sort > "$TIMELINE_FILE"

echo "Timeline saved to: $TIMELINE_FILE"
ls -lh "$OUT_DIR"
