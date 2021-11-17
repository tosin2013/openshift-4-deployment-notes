#!/bin/bash

#set -x
#set -e

export SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})

#########################################################
## Required Files
export SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export PULL_SECRET_PATH="$HOME/ocp-pull-secret"
export RH_OFFLINE_TOKEN_PATH="$HOME/rh-api-offline-token"

#########################################################
## Required Configuration
export CLUSTER_NAME="ai-poc"
export CLUSTER_BASE_DNS="lab.local"
export CLUSTER_INGRESS_VIP="192.167.124.8"
export CLUSTER_API_VIP="192.167.124.9"
export CLUSTER_MACHINE_NETWORK="192.167.124.0/24"
export NTP_SOURCE="time1.google.com"

#########################################################
## Optional Configuration
export CLUSTER_VERSION="4.9"
## CLUSTER_RELEASE has been moved to query-supported-versions.sh
#export CLUSTER_RELEASE="4.9.6"
# ISO_TYPE can be 'minimal-iso' or 'full-iso'
export ISO_TYPE="minimal-iso"

# CORE_USER_PWD - Leave blank to not set a core user password
export CORE_USER_PWD=""

#########################################################
## NOTHING TO SEE HERE - Don't edit past this point

echo -e "\n===== Generating asset directory..."
GENERATED_ASSETS="${SCRIPT_DIR}/.generated"
export CLUSTER_DIR="${GENERATED_ASSETS}/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}"
mkdir -p ${CLUSTER_DIR}

## Set Cluster ID
export CLUSTER_ID=""
if [ -f "${CLUSTER_DIR}/.cluster-id.nfo" ]; then
  export CLUSTER_ID=$(cat ${CLUSTER_DIR}/.cluster-id.nfo)
fi

## Check/load SSH Public Key
if [ -f "$SSH_PUB_KEY_PATH" ]; then
  export CLUSTER_SSH_PUB_KEY=$(cat ${SSH_PUB_KEY_PATH})
else
  echo "No SSH Public Key found!  Looking for ${SSH_PUB_KEY_PATH}"
  exit 1
fi
## Check/load Pull Secret
if [ -f "$PULL_SECRET_PATH" ]; then
  export PULL_SECRET=$(cat ${PULL_SECRET_PATH} | jq -R .)
else
  echo "No Pull Secret found!  Looking for ${PULL_SECRET_PATH}"
  exit 1
fi
## Check/load Offline Token
if [ -f "$RH_OFFLINE_TOKEN_PATH" ]; then
  export RH_OFFLINE_TOKEN=$(cat ${RH_OFFLINE_TOKEN_PATH})
else
  echo "No RH API Offline Token found!  Looking for ${RH_OFFLINE_TOKEN_PATH}"
  exit 1
fi

export ASSISTED_SERVICE_HOSTNAME="api.openshift.com"
export ASSISTED_SERVICE_PORT="443" 
export ASSISTED_SERVICE_PROTOCOL="https"
export ASSISTED_SERVICE_ENDPOINT="${ASSISTED_SERVICE_PROTOCOL}://${ASSISTED_SERVICE_HOSTNAME}:${ASSISTED_SERVICE_PORT}"
export ASSISTED_SERVICE_V1_API_PATH="/api/assisted-install/v1"
export ASSISTED_SERVICE_V2_API_PATH="/api/assisted-install/v2"
export ASSISTED_SERVICE_V1_API="${ASSISTED_SERVICE_ENDPOINT}${ASSISTED_SERVICE_V1_API_PATH}"
export ASSISTED_SERVICE_V2_API="${ASSISTED_SERVICE_ENDPOINT}${ASSISTED_SERVICE_V2_API_PATH}"

export CLUSTER_OVN="OVNKubernetes"

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

echo -e "===== Authenticating to the Red Hat API..."
export ACTIVE_TOKEN=$(curl -s --fail https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$RH_OFFLINE_TOKEN | jq .access_token  | tr -d '"')
if [ -z "$ACTIVE_TOKEN" ]; then
  echo "Failed to authenticate with the RH API!"
  exit 1
fi

echo -e "===== Preflight passed...\n"