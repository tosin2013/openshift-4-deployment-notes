#!/bin/bash

#### TODO
#### THIS SCRIPT NEEDS TO BE REWORKED TO THE INFRAENV ENDPOINTS
#### https://github.com/kenmoini/ocp4-ai-svc-universal/blob/main/tasks/ai-svc/set_core_user_password.yaml

set -e

echo -e "\n===== Setting password authentication for core user..."

if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
fi

## Download the discovery.ign file from the AI Svc
DISCOVERY_IGN_URL=${ASSISTED_SERVICE_V1_API}/clusters/${TARGET_CLUSTER_ID}/downloads/'files?file_name=discovery.ign'

ORIGINAL_IGNITION_REQ=$(curl -s \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Accept: application/octet-stream" \
--request GET \
${DISCOVERY_IGN_URL})

if [ -z "$ORIGINAL_IGNITION_REQ" ]; then
  echo "===== Failed to fetch original discovery ignition file!"

  echo "===== Original discovery ignition file:"
  echo "${ORIGINAL_IGNITION_REQ}" | python3 -m json.tool
  exit 1
fi

## Generated a salted hash of the desired password
PASS_HASH=$(python3 -c 'import crypt; print(crypt.crypt("'$CORE_USER_PWD'", crypt.mksalt(crypt.METHOD_SHA512)))' | tr -d '\n')

## Patch the discovery.ign
NEW_IGNITION=$(<<< "$ORIGINAL_IGNITION_REQ" jq --arg passhash "$PASS_HASH" '.passwd.users[0].passwordHash = $passhash')
NEW_IGNITION=$(<<< "$NEW_IGNITION" jq '.passwd.users[0].name = "core"')
NEW_IGNITION_FILE=$(mktemp -p $CLUSTER_DIR)
echo $NEW_IGNITION > $NEW_IGNITION_FILE

PATCHED_IGN_FILE=$(mktemp -p $CLUSTER_DIR)
echo '{"config": "replaceme"}' | jq --arg ignition "$(cat $NEW_IGNITION_FILE)" '.config = $ignition' > $PATCHED_IGN_FILE

## Patch the API with the patched discovery.ign
PATCH_CURL_FILE=$(mktemp -p $CLUSTER_DIR)
PATCH_CORE_USER_PASSWORD_REQ=$(curl -s -o $PATCH_CURL_FILE -w "%{http_code}" --header "Authorization: Bearer $ACTIVE_TOKEN" --header "Content-Type: application/json" --request PATCH --data @$PATCHED_IGN_FILE ${ASSISTED_SERVICE_V1_API}/clusters/${TARGET_CLUSTER_ID}/discovery-ignition)

if [ "$PATCH_CORE_USER_PASSWORD_REQ" -ne "201" ]; then
  echo "===== Failed to patch discovery ignition file with core user password!"
  cat $PATCH_CURL_FILE
  exit 1
fi

## Clean up
rm $NEW_IGNITION_FILE
rm $PATCHED_IGN_FILE
rm $PATCH_CURL_FILE
