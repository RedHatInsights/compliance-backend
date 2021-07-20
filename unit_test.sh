#!/bin/bash

ACG_CONFIG="$(pwd)/cdappconfig.json" bundle exec rake test:validate

if [ $? != 0 ]; then
    exit 1
fi
