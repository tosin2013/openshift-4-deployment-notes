#!/bin/bash

set -e

echo -e "\n===== Creating Add Hosts cluster..."

generateImportPatchData() {
cat << EOF
{
  "name": "${CLUSTER_NAME}",
  "api_vip_dnsname": "api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS}",
  "openshift_cluster_id": "00000000-0000-0000-0000-000000000000"
}
EOF
}

generateImportInfraEnvPatchData() {
cat << EOF
{
  "name": "${CLUSTER_NAME}",
  "image_type": "full-iso",
  "cluster_id": "${NEW_CLUSTER_ID}",
  "ssh_authorized_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

generateAddHostPatchData() {
cat << EOF
{
  "id": "${NEW_CLUSTER_ID}",
  "name": "${CLUSTER_NAME}",
  "openshift_version": "${CLUSTER_VERSION}",
  "api_vip_dnsname": "api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS}",
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

generateAddHostBasicPatchData() {
cat << EOF
{
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

echo "  Building for cluster at api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS}"

## check for the new cluster id and infraenv id
export NEW_CLUSTER_ID=""
export NEW_INFRAENV_ID=""

if [ -f "${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo" ]; then
  NEW_CLUSTER_ID=$(cat "${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo")
  echo -e "  NEW_CLUSTER_ID found, using ${NEW_CLUSTER_ID} ..."
fi

if [ -f "${CLUSTER_DIR}/.new-infraenv-id-${HOSTS_MD5}.nfo" ]; then
  NEW_INFRAENV_ID=$(cat "${CLUSTER_DIR}/.new-infraenv-id-${HOSTS_MD5}.nfo")
  echo -e "  NEW_INFRAENV_ID found, using ${NEW_INFRAENV_ID} ..."
fi



## Check to see if the cluster id is already set
if [ -z "$NEW_CLUSTER_ID" ]; then
  echo -e "  No NEW_CLUSTER_ID found, importing cluster..."
  
  CREATE_ADD_HOST_CLUSTER_REQ=$(curl -s --fail \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
  --data "$(generateImportPatchData)" \
  "${ASSISTED_SERVICE_V2_API}/clusters/import")

  if [ -z "$CREATE_ADD_HOST_CLUSTER_REQ" ]; then
    echo "===== Failed to create AddHosts cluster!"
    exit 1
  fi

  #echo $CREATE_ADD_HOST_CLUSTER_REQ | python3 -m json.tool

  export NEW_CLUSTER_ID=$(printf '%s' "$CREATE_ADD_HOST_CLUSTER_REQ" | jq -r '.id')
  echo "  NEW_CLUSTER_ID: ${NEW_CLUSTER_ID}"
  echo $NEW_CLUSTER_ID > ${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo
  
fi

## Check to see if the InfraEnv ID is already set
if [ -z "$NEW_INFRAENV_ID" ]; then
  echo -e "  No NEW_INFRAENV_ID found, importing cluster..."
  
  CREATE_ADD_HOST_INFRAENV_REQ=$(curl -s --fail \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
  --data "$(generateImportInfraEnvPatchData)" \
  "${ASSISTED_SERVICE_V2_API}/infra-envs")

  if [ -z "$CREATE_ADD_HOST_INFRAENV_REQ" ]; then
    echo "===== Failed to create AddHosts InfraEnv!"
    exit 1
  fi

  #echo $CREATE_ADD_HOST_INFRAENV_REQ | python3 -m json.tool

  export NEW_INFRAENV_ID=$(printf '%s' "$CREATE_ADD_HOST_INFRAENV_REQ" | jq -r '.id')
  echo "  NEW_INFRAENV_ID: ${NEW_INFRAENV_ID}"
  echo $NEW_INFRAENV_ID > ${CLUSTER_DIR}/.new-infraenv-id-${HOSTS_MD5}.nfo
  
fi
