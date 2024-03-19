#!/bin/bash

set -e

generateInfraenvPatchData() {
cat << EOF
{
  "name": "${CLUSTER_NAME}",
  "image_type": "full-iso",
  "cluster_id": "${CLUSTER_ID}",
  "cpu_architecture": "${CLUSTER_ARCH}",
  "pull_secret": $PULL_SECRET
}
EOF
}

## Save to file anyway for debugging purposes
echo "$(generateInfraenvPatchData)" > ${CLUSTER_DIR}/infraenv-config.json

echo "===== Creating a new InfraEnv..."

CREATE_INFRAENV_REQUEST=$(curl -s --fail \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--request POST \
--data "$(generateInfraenvPatchData)" \
"${ASSISTED_SERVICE_V2_API}/infra-envs")

if [ -z "$CREATE_INFRAENV_REQUEST" ]; then
  echo "===== Failed to create InfraEnv!"
  exit 1
fi

INFRAENV_ID=$(printf '%s' "$CREATE_INFRAENV_REQUEST" | jq -r '.id')
echo "  INFRAENV_ID: ${INFRAENV_ID}"
echo $INFRAENV_ID > ${CLUSTER_DIR}/.infraenv-id.nfo