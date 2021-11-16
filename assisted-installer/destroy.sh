#!/bin/bash

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

#########################################################
## Check to see if the Cluster ID is available
if [ -z "$CLUSTER_ID" ]; then
  ## No CLUSTER_ID, just delete the general cluster files
  echo "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} not found, not able to delete from the API..."
else
  ## CLUSTER_ID file is intact, let's delete the cluster from the Assisted Installer service
  echo "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} found, deleting from API..."

  ## Delete the cluster from the Assisted Service...
  DELETE_CLUSTER_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request DELETE \
  "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID")
fi

rm -rf ${CLUSTER_DIR}/