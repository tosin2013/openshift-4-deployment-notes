#!/bin/bash
set -x
set -e

source ./cluster-vars.sh
source ./authenticate-to-api.sh

curl -X POST "${ASSISTED_SERVICE_ENDPOINT}/api/assisted-install/v1/clusters/$NCLUSTER_ID/actions/install_hosts" \
-H "accept: application/json" \
-H "Authorization: Bearer $ACTIVE_TOKEN" | jq '.'

### next Steps
