#!/bin/bash

set -exv

# Make directory for artifacts
mkdir -p artifacts

cat << EOF > artifacts/junit-dummy.xml
<testsuite tests="1">
    <testcase classname="dummy" name="dummytest"/>
</testsuite>
EOF
