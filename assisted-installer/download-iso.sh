#!/bin/bash

set -e
#set -x
if [ -z $1 ];
then 
  WORKER_ISO_NAME=""
else 
  WORKER_ISO_NAME=$1
fi

echo -e "\n===== Waiting 15s for ISO to build...\n"
sleep 15

## Download Discovery ISO
if [ -z ${WORKER_ISO_NAME} ];
then
  ## Get InfraEnv information
  INFRA_ENV=$(curl -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID")

  ISO_DOWNLOAD_LINK=$(echo $INFRA_ENV | jq -r '.download_url')
  echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso ...\n"
  curl \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ISO_DOWNLOAD_LINK}" \
    -o ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso
else
  ## Get InfraEnv information
  INFRA_ENV=$(curl -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V2_API}/infra-envs/${2}")

  ISO_DOWNLOAD_LINK=$(echo $INFRA_ENV | jq -r '.download_url')

  echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/${WORKER_ISO_NAME}.iso ...\n"
  curl \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ISO_DOWNLOAD_LINK}" \
    -o ${CLUSTER_DIR}/${WORKER_ISO_NAME}.iso
fi
