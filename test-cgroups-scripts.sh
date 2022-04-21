#!/usr/bin/bash

COMPLIANCE_IMAGE_TAG="${1:-29ac074}"

expected_output=$(podman run --rm  quay.io/cloudservices/compliance-backend:${COMPLIANCE_IMAGE_TAG} "cgroup-limits" 2>/dev/null)
actual_output=$(podman run --rm  quay.io/cloudservices/compliance-backend:${COMPLIANCE_IMAGE_TAG} /bin/bash -c 'echo $(env -i bash -c "scripts/set_cgroup_limits.sh  2>/dev/null && env")')

formatted_actual_output=$(sed -e 's/\s/\n/g' <<<"$actual_output" | sed -e '/^\(PWD\|SHLVL\|_\)=.*$/d')

diff <(echo "$expected_output") <(echo "$formatted_actual_output")
