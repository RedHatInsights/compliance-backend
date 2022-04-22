
JUNIT_RESULT_REPORT="${ARTIFACTS_DIR}/junit-e2e-cgroup-limits-tests.xml"

echo '<?xml version="1.0" encoding="UTF-8"?>' > "$JUNIT_RESULT_REPORT"
echo '<testsuite tests="2">' >> "$JUNIT_RESULT_REPORT"

#TODO: create Junit result report
# Run E2E test for cgroup-limits, local container engine
LOCAL_TESTS_OUTPUT=$($APP_ROOT/run-e2e-cgroup-limits-test-local-container.sh "$IMAGE_TAG")
LOCAL_TESTS_EXIT_CODE=$?

echo '<testcase classname="e2e-cgroup-limits-tests" name="local-container">' >> "$JUNIT_RESULT_REPORT"

if [ "$LOCAL_TESTS_EXIT_CODE" -ne 0 ]; then
   echo "<failure message=\"run-e2e-cgroup-limits-test-local-container FAILED\">" >> "$JUNIT_RESULT_REPORT"   
   echo "$LOCAL_TESTS_OUTPUT" >> "$JUNIT_RESULT_REPORT"
   echo "</failure>" >> "$JUNIT_RESULT_REPORT"   
fi

echo '</testcase>' >> "$JUNIT_RESULT_REPORT"

#TODO: create Junit result report
# Run E2E test for cgroup-limits, remote Openshift cluster
REMOTE_TESTS_OUTPUT=$($APP_ROOT/run-e2e-cgroup-limits-test-remote-cluster.sh "$IMAGE_TAG")
REMOTE_TESTS_EXIT_CODE=$?

echo '<testcase classname="e2e-cgroup-limits-tests" name="remote-cluster">' >> "$JUNIT_RESULT_REPORT"

if [ "$REMOTE_TESTS_EXIT_CODE" -ne 0 ]; then
   echo "<failure message=\"run-e2e-cgroup-limits-test-remote-cluster FAILED\">" >> "$JUNIT_RESULT_REPORT"   
   echo "$REMOTE_TESTS_OUTPUT" >> "$JUNIT_RESULT_REPORT"
   echo "</failure>" >> "$JUNIT_RESULT_REPORT"   
fi

echo '</testcase>' >> "$JUNIT_RESULT_REPORT"

echo "</testsuite>" >> "$JUNIT_RESULT_REPORT"
