#!/bin/bash

set -e

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

#########################################################
## Perform preflight checks
source $SCRIPT_DIR/preflight.sh

echo -e "\n===== Deleting cluster $1..."

DELETE_ADD_HOST_CLUSTER_REQ=$(curl -s -o /dev/null -w "%{http_code}" \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--request DELETE \
"${ASSISTED_SERVICE_V1_API}/clusters/${1}")

if [ "$DELETE_ADD_HOST_CLUSTER_REQ" -ne "204" ]; then
  echo "===== Failed to delete  cluster!"
  exit 1
fi
