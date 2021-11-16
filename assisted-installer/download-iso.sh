#!/bin/bash

## Asssumes ./cluster-vars.sh has been source'd
## Bash execution modes are inherited from cluster-vars.sh
##set -xe

## Download Discovery ISO
curl \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  -L "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID/downloads/image" \
  -o ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso