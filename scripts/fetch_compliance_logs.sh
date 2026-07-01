#!/usr/bin/env bash

# Exit on error
set -e

# Ensure we are logged into oc
if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift."
    echo "Please run 'oc login' first."
    exit 1
fi

if [ -n "$1" ]; then
    CURRENT_PROJECT="$1"
else
    if ! oc project &>/dev/null; then
        echo "Error: No project selected and no project provided."
        echo "Usage: $0 [project_name]"
        exit 1
    fi
    CURRENT_PROJECT=$(oc project -q)
fi

echo "Using project: $CURRENT_PROJECT"

# Ask user for source/context
read -p "Enter source/context for these logs (e.g., jenkins, local-bonfire, no-sidekiq): " RAW_SOURCE
if [[ -z "$RAW_SOURCE" ]]; then
    SOURCE="unknown"
else
    # Slugify the input: convert to lowercase, replace non-alphanumeric chars with dashes, squeeze multiple dashes
    SOURCE=$(echo "$RAW_SOURCE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')
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
        
        # Try fetching logs with strict timestamps
        # We pipe to awk to inject the pod_name right after the timestamp so we know who logged it when we merge
        # Format: 2026-06-26T14:50:42.123456Z [pod-name] original log line
        oc logs "$POD_NAME" -c "$CONTAINER" -n "$CURRENT_PROJECT" --timestamps 2>/dev/null | awk -v pod="[$POD_NAME]" '{timestamp=$1; $1=""; print timestamp " " pod $0}' > "$LOG_FILE" || echo "     (No logs available or container not started)"
        
        # Also grab previous logs if container restarted
        PREV_LOG_FILE="$OUT_DIR/${POD_NAME}_${CONTAINER}_previous.log"
        oc logs "$POD_NAME" -c "$CONTAINER" -n "$CURRENT_PROJECT" --previous --timestamps 2>/dev/null | awk -v pod="[$POD_NAME]" '{timestamp=$1; $1=""; print timestamp " " pod $0}' > "$PREV_LOG_FILE" || rm -f "$PREV_LOG_FILE"
    done
done

echo ""
echo "Done! All logs saved to $OUT_DIR"

TIMELINE_FILE="$OUT_DIR/00-merged-timeline.txt"
echo "Creating merged timeline of all init events..."
# Because all lines now start with the standard ISO8601 timestamp (e.g. 2026-06-26T...),
# we can just cat all init logs and sort them. We use -h in grep (or just cat) to avoid filename prefixes.
cat "$OUT_DIR"/*init.log 2>/dev/null | sort > "$TIMELINE_FILE"

echo "Timeline saved to: $TIMELINE_FILE"
ls -lh "$OUT_DIR"
