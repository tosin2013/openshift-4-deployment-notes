#!/bin/bash

set -e

source cluster-vars.sh
source authenticate-to-api.sh

echo -e "\n===== Waiting 15s for ISO to build...\n"
sleep 15

## Download Discovery ISO


if [ ! -z ${NEW_CLUSTER_ID} ];
then
  #mv ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso ${CLUSTER_DIR}/ai-liveiso-addhosts-$CLUSTER_ID.iso 
  #echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso ...\n"
  ## Get InfraEnv information
  INFRA_ENV=$(curl -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID")

  ISO_DOWNLOAD_LINK=$(echo $INFRA_ENV | jq -r '.download_url')

  curl \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ISO_DOWNLOAD_LINK}" \
    -o ${CLUSTER_DIR}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso
  echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso ...\n"

else 
  echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso ...\n"
  ## Get InfraEnv information
  INFRA_ENV=$(curl -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID")

  ISO_DOWNLOAD_LINK=$(echo $INFRA_ENV | jq -r '.download_url')

  curl \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ISO_DOWNLOAD_LINK}" \
    -o ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso
fi
