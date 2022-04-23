#!/usr/bin/env bash

echo '========================================'
echo '=== Running E2E cgroup-limits tests ===='
echo '========================================'

JUNIT_RESULT_REPORT="${ARTIFACTS_DIR}/junit-e2e-cgroup-limits-tests.xml"

touch "$JUNIT_RESULT_REPORT"

{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<testsuite tests="2">'

} >> "$JUNIT_RESULT_REPORT"

echo '================================================='
echo '=== E2E cgroup-limits test - local container ===='
echo '================================================='

LOCAL_TESTS_OUTPUT=$("${APP_ROOT}/e2e-test-cgroup-limits/run-e2e-cgroup-limits-test-local-container.sh" "$IMAGE_TAG")
LOCAL_TESTS_EXIT_CODE=$?

echo '<testcase classname="e2e-cgroup-limits-tests" name="local-container">' >> "$JUNIT_RESULT_REPORT"

if [ "$LOCAL_TESTS_EXIT_CODE" -ne 0 ]; then
    {
        echo "<failure message=\"run-e2e-cgroup-limits-test-local-container FAILED\">"
        echo "$LOCAL_TESTS_OUTPUT"
        echo "</failure>"
    } >> "$JUNIT_RESULT_REPORT"
fi

echo '</testcase>' >> "$JUNIT_RESULT_REPORT"

echo '================================================'
echo '=== E2E cgroup-limits test - remote cluster ===='
echo '================================================'

REMOTE_TESTS_OUTPUT=$("${APP_ROOT}/e2e-test-cgroup-limits/run-e2e-cgroup-limits-test-remote-cluster.sh" "$IMAGE_TAG")
REMOTE_TESTS_EXIT_CODE=$?

echo '<testcase classname="e2e-cgroup-limits-tests" name="remote-cluster">' >> "$JUNIT_RESULT_REPORT"

if [ "$REMOTE_TESTS_EXIT_CODE" -ne 0 ]; then
    {
        echo "<failure message=\"run-e2e-cgroup-limits-test-remote-cluster FAILED\">"
        echo "$REMOTE_TESTS_OUTPUT"
        echo "</failure>"
    } >> "$JUNIT_RESULT_REPORT"
fi

{
    echo '</testcase>'
    echo "</testsuite>"
} >> "$JUNIT_RESULT_REPORT"

echo '================================================='
echo '=== E2E cgroup-limits tests finished running ===='
echo '================================================='
