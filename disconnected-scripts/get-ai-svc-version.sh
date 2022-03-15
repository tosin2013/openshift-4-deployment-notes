#!/bin/bash

## Set needed variables
MIRROR_BASE_PATH=${HOME}

if [ ! -f $HOME/rh-api-offline-token ];
then 
   echo "$HOME/rh-api-offline-token not found"
   echo "rh-api-offline-token is the token generated from this page: https://access.redhat.com/management/api"
   exit
fi 
# RH_API_OFFLINE_TOKEN is the token generated from this page: https://access.redhat.com/management/api
RH_API_OFFLINE_TOKEN=$(cat $HOME/rh-api-offline-token)

ASSISTED_SERVICE_V2_API="https://api.openshift.com/api/assisted-install/v2"


## Authenticate to the RH API and get the Access Token
export ACCESS_TOKEN=$(curl -s --fail https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$RH_API_OFFLINE_TOKEN | jq .access_token  | tr -d '"')

## Check to make sure an Access token was obtains
if [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to authenticate with the RH API!"
  exit 1
fi

## Query the Assisted Installer Service for available versions
QUERY_CLUSTER_VERSIONS_REQUEST=$(curl -s --fail \
--header "Authorization: Bearer $ACCESS_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--request GET \
"${ASSISTED_SERVICE_V2_API}/openshift-versions")

## Check to make sure we retrieved data
if [ -z "$QUERY_CLUSTER_VERSIONS_REQUEST" ]; then
  echo "Failed to find supported cluster release version!"
  exit 1
fi

## Save the versions to a JSON file for use later
echo $QUERY_CLUSTER_VERSIONS_REQUEST > ${MIRROR_BASE_PATH}/cluster-versions.json
