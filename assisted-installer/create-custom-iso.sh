#!/bin/bash 
set -xe 

if [ -f ~/offline-token.txt];
then 
  echo "offline-token not found in $HOME directory"
  echo "create offline token and try again"
  exit 1
fi 



offline_token=$(cat ~/offline-token.txt)
export ASSISTED_SERVICE_IP="api.openshift.com"
export ASSISTED_SERVICE_PORT="443" 
CLUSTER_ID="9c14b495-f437-4869-9196-062661585c31"
#PULL_SECRET=$(cat ~/pull-secret.txt)
SSHKEY_NAME="id_rsa.pub"
CLUSTER_SSHKEY=$(cat ~/.ssh/${SSHKEY_NAME})
MAC1="52:54:00:00:00:01"
MAC2="52:54:00:00:00:02"
MAC3="52:54:00:00:00:03"


ACTIVE_TOKEN=$(curl -s https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token | jq .access_token  | tr -d '"')

echo ${ACTIVE_TOKEN}
jq -n --arg SSH_KEY "$CLUSTER_SSHKEY" --arg NMSTATE_YAML1 "$(cat ocp01.yaml)" --arg NMSTATE_YAML2 "$(cat ocp02.yaml)" --arg NMSTATE_YAML3 "$(cat ocp03.yaml)" \
'{
  "ssh_public_key": $SSH_KEY,
  "image_type": "full-iso",
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "'${MAC1}'", "logical_nic_name": "enp1s0"}]
    },
    {
      "network_yaml": $NMSTATE_YAML2,
      "mac_interface_map": [{"mac_address": "'${MAC2}'", "logical_nic_name": "enp1s0"}]
    },
    {
      "network_yaml": $NMSTATE_YAML3,
      "mac_interface_map": [{"mac_address": "'${MAC3}'", "logical_nic_name": "enp1s0"}]
    }
  ]
}' > msg_body.json

cat msg_body.json


curl -s -X POST "https://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/image" \
  -d @msg_body.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  | jq '.'

curl \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  -L "https://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/image" \
  -o ai-liveiso-$CLUSTER_ID.iso