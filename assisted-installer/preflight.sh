#!/bin/bash

set -e

echo -e "\n===== Running preflight...\n"

echo -e "===== Generating asset directory..."
mkdir -p ${CLUSTER_DIR}

#########################################################
## Global Functions
function checkForProgramAndExit() {
    command -v $1 > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        printf '%-72s %-7s\n' $1 "PASSED!";
    else
        printf '%-72s %-7s\n' $1 "FAILED!";
        exit 1
    fi
}

echo -e "===== Checking for needed programs..."
checkForProgramAndExit curl
checkForProgramAndExit jq
checkForProgramAndExit python3
checkForProgramAndExit dig
checkForProgramAndExit j2cli

source $SCRIPT_DIR/authenticate-to-api.sh

source $SCRIPT_DIR/query-openshift-versions.sh

source $SCRIPT_DIR/validate-environment.sh

echo -e "===== Preflight passed...\n"
