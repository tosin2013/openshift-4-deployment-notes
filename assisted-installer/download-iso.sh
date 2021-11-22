#!/bin/bash

set -e
set -x 
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
  echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso ...\n"
  curl \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID/downloads/image" \
    -o ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso
else
  echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/${WORKER_ISO_NAME}.iso ...\n"
  curl \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -L "${ASSISTED_SERVICE_V1_API}/clusters/${2}/downloads/image" \
    -o ${CLUSTER_DIR}/${WORKER_ISO_NAME}.iso
fi
