#!/bin/bash

#set -e

if [ ${SELF_HOSTED_INSTALLER} == "true" ]; then
    echo -e "===== using ${ASSISTED_SERVICE_ENDPOINT}..."
    export ACTIVE_TOKEN="dummy"
else 
  echo -e "===== Authenticating to the Red Hat API..."
  export ACTIVE_TOKEN=$(curl -s --fail https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$RH_OFFLINE_TOKEN | jq .access_token  | tr -d '"')
fi 

if [ -z "$ACTIVE_TOKEN" ]; then
  echo "Failed to authenticate with the RH API!"
  exit 1
fi
echo -e "  Using Token: ${ACTIVE_TOKEN:0:15}...\n"
