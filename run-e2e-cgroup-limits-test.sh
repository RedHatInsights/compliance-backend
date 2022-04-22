#!/usr/bin/env bash

TARGET_IMAGE_TAG=${1:-latest}

POD_TEMPLATE='./custom-template.yaml'
TARGET_IMAGE="quay.io/cloudservices/compliance-backend:${TARGET_IMAGE_TAG}"
REFERENCE_POD_NAME='reference'
TARGET_POD_NAME='target'
POD_NAME='e2e-test-for-compliance-cgroups-limit-script'
TEARDOWN_RAN=0
DIFF_STATUS=1
EXIT_CODE=0

function teardown {

    oc delete pod --now "$POD_NAME" --namespace "$TEST_NAMESPACE"
#    bonfire namespace release "$TEST_NAMESPACE"

    exit $EXIT_CODE
}

trap teardown EXIT SIGINT SIGTERM

#TEST_NAMESPACE=$(bonfire namespace reserve)
TEST_NAMESPACE='ephemeral-62w6lz'

oc create -f "$POD_TEMPLATE" --namespace "$TEST_NAMESPACE"
oc wait --for=condition=Ready --namespace "$TEST_NAMESPACE" "pod/${POD_NAME}" 

EXPECTED_OUTPUT=$(oc logs --namespace "$TEST_NAMESPACE" "$POD_NAME" -c 'reference' | sort) 
ACTUAL_OUTPUT=$(oc logs --namespace "$TEST_NAMESPACE" "$POD_NAME" -c 'target')
FORMATTED_ACTUAL_OUTPUT=$(sed -e 's/\s/\n/g' <<<"$ACTUAL_OUTPUT" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d' | sort)

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
