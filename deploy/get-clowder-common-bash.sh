#!/usr/bin/env bash

set -e

WORKDIR=$(dirname "$0")
VERSION='992e8a167dcdb96895c68cfab5f416e76caa57e6'
FILENAME='clowder-config-main'
FILEPATH="${WORKDIR}/${FILENAME}"
INTEGRITY_FILE="${FILENAME}.sha256"
URL="https://raw.githubusercontent.com/RedHatInsights/clowder-common-bash/${VERSION}/${FILENAME}"

check_integrity() {
    ( cd "$WORKDIR" && sha256sum --quiet -c "$INTEGRITY_FILE" >/dev/null 2>&1 )
}

artifact_exists() {
    [[ -e "$FILEPATH" ]]
}

download_artifact() {
    curl -sL "$URL" -o "$FILEPATH"
}

if ! artifact_exists || ! check_integrity; then

    rm -f "$FILEPATH" && download_artifact

    if ! artifact_exists || ! check_integrity; then
        echo "Error checking integrity of $FILEPATH"
        exit 1
    fi
fi

echo "$FILEPATH"
