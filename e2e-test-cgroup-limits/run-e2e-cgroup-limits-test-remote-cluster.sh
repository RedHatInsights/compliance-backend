#!/usr/bin/env bash

TARGET_IMAGE_TAG=${1:-latest}

POD_TEMPLATE="${APP_ROOT}/e2e-test-cgroup-limits/e2e-test-cgroup-limits-template.yaml"
POD_NAME='e2e-test-for-compliance-cgroups-limit'
QUAY_PULL_SECRET='quay-cloudservices-pull'
EXIT_CODE=0

function teardown {

    oc delete pod --now "$POD_NAME" --namespace "$TEST_NAMESPACE"
    oc secrets unlink default "$QUAY_PULL_SECRET" --namespace "$TEST_NAMESPACE"
    bonfire namespace release "$TEST_NAMESPACE" -f

    exit $EXIT_CODE
}

trap teardown EXIT SIGINT SIGTERM

TEST_NAMESPACE=$(bonfire namespace reserve)
oc secrets link --for=pull default "$QUAY_PULL_SECRET" quay-cloudservices-pull --namespace "$TEST_NAMESPACE"

oc process -f "$POD_TEMPLATE" --namespace "$TEST_NAMESPACE" -p "IMAGE_TAG=${TARGET_IMAGE_TAG}" -p "NAMESPACE=${TEST_NAMESPACE}" | oc create -f - --namespace "$TEST_NAMESPACE"
oc wait --for=condition=Ready --namespace "$TEST_NAMESPACE" "pod/${POD_NAME}"

EXPECTED_OUTPUT=$(oc logs --namespace "$TEST_NAMESPACE" "$POD_NAME" -c 'reference' | sort)
ACTUAL_OUTPUT=$(oc logs --namespace "$TEST_NAMESPACE" "$POD_NAME" -c 'target')
# shellcheck disable=SC2001
FORMATTED_ACTUAL_OUTPUT=$(sed -e 's/\s/\n/g' <<<"$ACTUAL_OUTPUT" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d' | sort)

if ! diff -q <(echo "$EXPECTED_OUTPUT") <(echo "$FORMATTED_ACTUAL_OUTPUT"); then

    echo "environment variables differ"
    echo "expected output:"
    echo "$EXPECTED_OUTPUT"
    echo "================"
    echo "actual output:"
    echo "$FORMATTED_ACTUAL_OUTPUT"
    echo "test/e2e-test-for-compliance-cgroups-limit-remote: FAILED"
    EXIT_CODE=1
else
    echo "test/e2e-test-for-compliance-cgroups-limit-remote: PASSED"
fi
