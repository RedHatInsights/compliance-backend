#!/bin/bash

COMPLIANCE_IMAGE_TAG="${1:-latest}"
EXIT_CODE=0

_check_command_is_present() {
    command -v "$1" >/dev/null
}

if _check_command_is_present "docker"; then
    CONTAINER_ENGINE="docker"
else
    CONTAINER_ENGINE="podman"
fi

expected_output=$("$CONTAINER_ENGINE" run --rm "registry.access.redhat.com/ubi8/ruby-30" "cgroup-limits" 2>/dev/null | sort)
# shellcheck disable=SC2016
actual_output=$("$CONTAINER_ENGINE" run --rm  "quay.io/cloudservices/compliance-backend:${COMPLIANCE_IMAGE_TAG}" "/bin/bash" "-c" 'echo $(env -i bash -c "scripts/set_cgroup_limits.sh  2>/dev/null && env")')

# shellcheck disable=SC2001
formatted_actual_output=$(sed -e 's/\s/\n/g' <<<"$actual_output" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d' | sort)

if ! diff -q <(echo "$expected_output") <(echo "$formatted_actual_output"); then

    echo "environment variables differ"
    echo "expected output:"
    echo "$expected_output"
    echo "================"
    echo "actual output:"
    echo "$formatted_actual_output"

    echo "test/e2e-test-for-compliance-cgroups-limit-local: FAILED"
    EXIT_CODE=1
else
    echo "test/e2e-test-for-compliance-cgroups-limit-local: PASSED"
fi

exit $EXIT_CODE
