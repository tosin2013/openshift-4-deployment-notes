#!/bin/bash

set -ex

## Check/load SSH Public Key
if [ -f "$SSH_PUB_KEY_PATH" ]; then
  export CLUSTER_SSH_PUB_KEY=$(cat ${SSH_PUB_KEY_PATH})
else
  echo "No SSH Public Key found!  Looking for ${SSH_PUB_KEY_PATH}"
  exit 1
fi

## Download the discovery.ign file from the AI Svc
DISCOVERY_IGN_URL=${ASSISTED_SERVICE_V2_API}/infra-envs/${INFRAENV_ID}/downloads/'files?file_name=discovery.ign'

ORIGINAL_IGNITION=$(curl -s --fail \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Accept: application/octet-stream" \
--request GET \
${DISCOVERY_IGN_URL})

if [ -z "$ORIGINAL_IGNITION" ]; then
  echo "===== Failed to fetch original discovery ignition file!"
  exit 1
fi

## Generated a salted hash of the desired password
PASS_HASH=$(python3 -c 'import crypt; print(crypt.crypt("'$CORE_USER_PWD'", crypt.mksalt(crypt.METHOD_SHA512)))' | tr -d '\n')

## Patch the discovery.ign
NEW_IGNITION=$(<<< "$ORIGINAL_IGNITION" jq --arg passhash "$PASS_HASH" '.passwd.users[0].passwordHash = $passhash')
NEW_IGNITION=$(<<< "$NEW_IGNITION" jq '.passwd.users[0].name = "core"')
#NEW_IGNITION=$(<<< "$NEW_IGNITION" jq '.passwd.users[0].groups = ["sudo"]')
#NEW_IGNITION=$(<<< "$NEW_IGNITION" jq '.passwd.users[0].uid = "1001"')
#NEW_IGNITION=$(<<< "$NEW_IGNITION" jq '.passwd.users[0].shell = "/bin/bash"')
#echo === CLUSTER_SSH_PUB_KEY patched ignition === 
#echo "$CLUSTER_SSH_PUB_KEY"
#NEW_IGNITION=$(<<< "$NEW_IGNITION" jq --arg clustersshpub "$CLUSTER_SSH_PUB_KEY" '.passwd.users[0].sshAuthorizedKeys = [$clustersshpub]')
NEW_IGNITION_FILE=$(mktemp -p $CLUSTER_DIR)
echo $NEW_IGNITION > $NEW_IGNITION_FILE

PATCHED_IGN_FILE=$(mktemp -p $CLUSTER_DIR)
echo '{"config": "replaceme"}' | jq --arg ignition "$(cat $NEW_IGNITION_FILE)" '.config = $ignition' > $PATCHED_IGN_FILE
cat $PATCHED_IGN_FILE

#echo === ORIGINAL_IGNITION patched ignition === 
#echo "$ORIGINAL_IGNITION" 
#echo === NEW_IGNITION patched ignition === 
#echo "$NEW_IGNITION_FILE" 
#echo ============================ 
## Patch the API with the patched discovery.ign
PATCH_CURL_FILE=$(mktemp -p $CLUSTER_DIR)
PATCH_CORE_USER_PASSWORD_REQ=$(curl -s -o $PATCH_CURL_FILE -w "%{http_code}" --header "Authorization: Bearer $ACTIVE_TOKEN" --header "Content-Type: application/json" --request PATCH --data @$PATCHED_IGN_FILE ${ASSISTED_SERVICE_V2_API}/infra-envs/${INFRAENV_ID})

if [ "$PATCH_CORE_USER_PASSWORD_REQ" -ne "201" ]; then
  echo "===== Failed to patch discovery ignition file with core user password!"
  exit 1
fi


## Clean up
rm $NEW_IGNITION_FILE
rm $PATCHED_IGN_FILE
rm $PATCH_CURL_FILE
