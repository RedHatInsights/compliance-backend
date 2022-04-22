#!/usr/bin/env bash

TARGET_IMAGE_TAG=${1:-latest}

REFERENCE_IMAGE='registry.access.redhat.com/ubi8/ruby-30'
TARGET_IMAGE="quay.io/cloudservices/compliance-backend:${TARGET_IMAGE_TAG}"
REFERENCE_POD_NAME='reference'
TARGET_POD_NAME='target'

# TODO: rollback this
#TEST_NAMESPACE=$(bonfire namespace reserve)
TEST_NAMESPACE='ephemeral-62w6lz'

oc run "$REFERENCE_POD_NAME" --namespace "$TEST_NAMESPACE" --image "$REFERENCE_IMAGE" --command -- "/bin/bash" "-c" "cgroup-limits 2>/dev/null && sleep infinity"
oc run "$TARGET_POD_NAME" --namespace "$TEST_NAMESPACE" --image "$TARGET_IMAGE" --command -- "/bin/bash" "-c" 'echo $(env -i bash -xc "scripts/set_cgroup_limits.sh  2>/dev/null && env") && sleep infinity' 
oc wait --for=condition=Ready --namespace "$TEST_NAMESPACE" "pod/${REFERENCE_POD_NAME}" 
oc wait --for=condition=Ready --namespace "$TEST_NAMESPACE" "pod/${TARGET_POD_NAME}" 
EXPECTED_OUTPUT=$(oc logs "$REFERENCE_POD_NAME" | sort -u) 
ACTUAL_OUTPUT=$(oc logs "$TARGET_POD_NAME")

FORMATTED_ACTUAL_OUTPUT=$(sed -e 's/\s/\n/g' <<<"$ACTUAL_OUTPUT" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d' | sort -u)

diff -q <(echo "$EXPECTED_OUTPUT") <(echo "$FORMATTED_ACTUAL_OUTPUT") 

if [[ $? -ne 0 ]]; then

    echo "environment variables differ"
    echo "expected output:"
    echo "$EXPECTED_OUTPUT"
    echo "================"
    echo "actual output:"
    echo "$FORMATTED_ACTUAL_OUTPUT"

    exit 1
fi

# TODO: trap this
oc delete pod "$REFERENCE_POD_NAME" "$TARGET_POD_NAME" --namespace "$TEST_NAMESPACE"
# TODO: uncomment
#bonfire namespace release $TEST_NAMESPACE
