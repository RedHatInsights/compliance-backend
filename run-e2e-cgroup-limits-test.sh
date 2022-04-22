#!/usr/bin/env bash

TARGET_IMAGE_TAG=${1:-latest}

REFERENCE_IMAGE='registry.access.redhat.com/ubi8/ruby-30'
TARGET_IMAGE="quay.io/cloudservices/compliance-backend:${TARGET_IMAGE_TAG}"
REFERENCE_POD_NAME='reference'
TARGET_POD_NAME='target'
TEARDOWN_RAN=0
EXIT_CODE=0

function teardown {

    oc delete pod --now "$REFERENCE_POD_NAME" "$TARGET_POD_NAME" --namespace "$TEST_NAMESPACE"
    bonfire namespace release "$TEST_NAMESPACE"

    exit $EXIT_CODE
}

trap teardown EXIT ERR SIGINT SIGTERM

set -e

TEST_NAMESPACE=$(bonfire namespace reserve)

oc run "$REFERENCE_POD_NAME" --namespace "$TEST_NAMESPACE" --image "$REFERENCE_IMAGE" --command -- "/bin/bash" "-c" "cgroup-limits 2>/dev/null && sleep infinity"
oc run "$TARGET_POD_NAME" --namespace "$TEST_NAMESPACE" --image "$TARGET_IMAGE" --command -- "/bin/bash" "-c" 'echo $(env -i bash -c "scripts/set_cgroup_limits.sh  2>/dev/null && env") && sleep infinity' 
oc wait --for=condition=Ready --namespace "$TEST_NAMESPACE" "pod/${REFERENCE_POD_NAME}" 
oc wait --for=condition=Ready --namespace "$TEST_NAMESPACE" "pod/${TARGET_POD_NAME}" 
EXPECTED_OUTPUT=$(oc logs --namespace "$TEST_NAMESPACE" "$REFERENCE_POD_NAME" | sort -u) 
ACTUAL_OUTPUT=$(oc logs --namespace "$TEST_NAMESPACE" "$TARGET_POD_NAME")
FORMATTED_ACTUAL_OUTPUT=$(sed -e 's/\s/\n/g' <<<"$ACTUAL_OUTPUT" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d' | sort -u)

diff -q <(echo "$EXPECTED_OUTPUT") <(echo "$FORMATTED_ACTUAL_OUTPUT") 

if [[ $? -ne 0 ]]; then

    echo "environment variables differ"
    echo "expected output:"
    echo "$EXPECTED_OUTPUT"
    echo "================"
    echo "actual output:"
    echo "$FORMATTED_ACTUAL_OUTPUT"

    EXIT_CODE=1
fi
