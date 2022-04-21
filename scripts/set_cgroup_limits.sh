#!/bin/bash

# Script for parsing cgroup information
# Inspired by https://github.com/sclorg/container-common-scripts/blob/master/shared-scripts/core/usr/bin/cgroup-limits

MEMORY_LIMIT_THRESHOLD_VALUE_IN_BYTES=92233720368547
export MAX_MEMORY_LIMIT_IN_BYTES=9223372036854775807
echo "MAX_MEMORY_LIMIT_IN_BYTES=${MAX_MEMORY_LIMIT_IN_BYTES}"

# Determine memory limit from cgroups
MEMORY_LIMIT_CGROUP="/sys/fs/cgroup/memory/memory.limit_in_bytes"
if [[ -f "${MEMORY_LIMIT_CGROUP}" ]]; then
  MEMORY_LIMIT=$(echo "$(cat $MEMORY_LIMIT_CGROUP)")
else
  MEMORY_LIMIT=$(echo "$(cat "/sys/fs/cgroup/memory.max")")
fi

# Set MEMORY_LIMIT_IN_BYTES
if [[ "${MEMORY_LIMIT}" == "max" ]]; then
  export MEMORY_LIMIT_IN_BYTES=$MAX_MEMORY_LIMIT_IN_BYTES
  echo "MEMORY_LIMIT_IN_BYTES=${MEMORY_LIMIT_IN_BYTES}"
elif [[ -z "${MEMORY_LIMIT}"  ]]; then
  echo "Warning: Can't detect memory limit from cgroups" >&2
else
  export MEMORY_LIMIT_IN_BYTES=$MEMORY_LIMIT
  echo "MEMORY_LIMIT_IN_BYTES=${MEMORY_LIMIT_IN_BYTES}"
fi

# Set NO_MEMORY_LIMIT
if [[ "${MEMORY_LIMIT_IN_BYTES}" -ge "${MEMORY_LIMIT_THRESHOLD_VALUE_IN_BYTES}" ]]; then
  export NO_MEMORY_LIMIT="true"
  echo "NO_MEMORY_LIMIT=true"
fi

# Determine nuber of cores from cgroups
CORES_CGROUP="/sys/fs/cgroup/cpuset/cpuset.cpus"
if [[ -f "${CORES_CGROUP}" ]]; then
  CORES=$(echo "$(cat $CORES_CGROUP)")
else
  CORES=$(cat "/sys/fs/cgroup/cpuset.cpus.effective")
fi

CORE_COUNT=0

# The group information about CPU count in the form of "A-B,C-D,..." that should be parsed into "B-A+1 + D-C+1 + ..."
for GROUP in $(echo "${CORES}" | tr "," "\n"); do
  left=$(cut -d- -f1 <<< "${GROUP}")
  right=$(cut -d- -f2 <<< "${GROUP}")

  if [[ -n "$right" ]]; then
    CORE_COUNT=$((CORE_COUNT + right - left + 1))
  else
    CORE_COUNT=$((CORE_COUNT + 1))
  fi
done

if [[ "${CORE_COUNT}" -ne 0 ]]; then
  export NUMBER_OF_CORES=$CORE_COUNT
  echo "NUMBER_OF_CORES=${NUMBER_OF_CORES}"
fi
