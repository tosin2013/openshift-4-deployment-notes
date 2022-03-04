#!/bin/bash

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi
source $SCRIPT_DIR/authenticate-to-api.sh

#########################################################
## Check to see if the Cluster ID is available
if [ -z "$INFRAENV_ID" ]; then
  ## No INFRAENV_ID, just delete the general cluster files
  echo "===== InfraEnv ${CLUSTER_NAME} not found, not able to delete from the API..."
else
  ## INFRAENV_ID file is intact, let's delete the InfraEnv from the Assisted Installer service
  echo "===== InfraEnv ${CLUSTER_NAME} with Cluster ID: $INFRAENV_ID found, deleting from API..."

  INFRA_ENV_HOSTS=$(curl -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID/hosts")

  for host in $(echo "${INFRA_ENV_HOSTS}" | jq -r '.[] | @base64'); do
    _jq() {
      echo ${host} | base64 --decode | jq -r ${1}
    }
    echo "  Deleting host $(_jq '.id')..."

    DELETE_HOST_REQ=$(curl -s \
      --header "Authorization: Bearer $ACTIVE_TOKEN" \
      --request DELETE \
    "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID/hosts/$(_jq '.id')")
  done

  ## Delete the Infraenv
  DELETE_INFRAENV_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --request DELETE \
  "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID")

fi

#########################################################
## Check to see if the Cluster ID is available
if [ -z "$CLUSTER_ID" ]; then
  ## No CLUSTER_ID, just delete the general cluster files
  echo "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} not found, not able to delete from the API..."
else
  ## CLUSTER_ID file is intact, let's delete the cluster from the Assisted Installer service
  echo "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} with Cluster ID: $CLUSTER_ID found, deleting from API..."

  ## Cancel the cluster from the Assisted Service...
  CANCEL_CLUSTER_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --request POST \
  "${ASSISTED_SERVICE_V2_API}/clusters/$CLUSTER_ID/actions/cancel")

  ## Reset the cluster from the Assisted Service...
  RESET_CLUSTER_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --request POST \
  "${ASSISTED_SERVICE_V2_API}/clusters/$CLUSTER_ID/actions/reset")

  ## Delete the cluster from the Assisted Service...
  DELETE_CLUSTER_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --request DELETE \
  "${ASSISTED_SERVICE_V2_API}/clusters/$CLUSTER_ID")
fi

rm -rf ${CLUSTER_DIR}/
