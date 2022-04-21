#!/usr/bin/bash

COMPLIANCE_IMAGE_TAG="${1:-29ac074}"



_check_command_is_present() {
    command -v $1 >/dev/null
}

if _check_command_is_present "docker"; then
    CONTAINER_ENGINE="docker"
else
    CONTAINER_ENGINE="podman"
fi

expected_output=$("$CONTAINER_ENGINE" run --rm  quay.io/cloudservices/compliance-backend:${COMPLIANCE_IMAGE_TAG} "cgroup-limits" 2>/dev/null | sort -u)
actual_output=$("$CONTAINER_ENGINE" run --rm  quay.io/cloudservices/compliance-backend:${COMPLIANCE_IMAGE_TAG} /bin/bash -c 'echo $(env -i bash -c "scripts/set_cgroup_limits.sh  2>/dev/null && env")')

formatted_actual_output=$(sed -e 's/\s/\n/g' <<<"$actual_output" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d' | sort -u)

diff <(echo "$expected_output") <(echo "$formatted_actual_output")
