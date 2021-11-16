#!/bin/bash
set -xe
export SSHKEY_NAME="id_rsa.pub"
export CLUSTER_SSHKEY=$(cat ~/.ssh/${SSHKEY_NAME})
export PULL_SECRET=$(cat ~/pull-secret.txt | jq -R .)
export CLUSTER_NAME="ai-poc"
export CLUSTER_VERSION="4.9"
export CLUSTER_RELEASE="4.9.6"
export BASE_DNS="lab.local"
export CLUSTER_INGRESS_VIP="192.167.124.8"
export CLUSTER_API_VIP="192.167.124.9"
export CLUSTER_MACHINE_NETWORK="192.167.124.0/24"
export NTP_SOURCE="time1.google.com"
export ASSISTED_SERVICE_IP="api.openshift.com"
export ASSISTED_SERVICE_PORT="443" 
export CLUSTER_OVN="OVNKubernetes"

if [ -f ~/offline-token.txt];
then 
  echo "offline-token not found in $HOME directory"
  echo "create offline token and try again"
  exit 1
fi 

offline_token=$(cat ~/offline-token.txt)
ACTIVE_TOKEN=$(curl -s https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token | jq .access_token  | tr -d '"')

generatePatchData() {
cat << EOF
{
  "kind": "Cluster",
  "name": "${CLUSTER_NAME}",  
  "openshift_version": "${CLUSTER_VERSION}",
  "ocp_release_image": "quay.io/openshift-release-dev/ocp-release:${CLUSTER_RELEASE}-x86_64",
  "base_dns_domain": "${BASE_DNS}",
  "hyperthreading": "all",
  "ingress_vip": "${CLUSTER_INGRESS_VIP}",
  "api_vip": "${CLUSTER_API_VIP}",
  "schedulable_masters": false,
  "high_availability_mode": "Full",
  "user_managed_networking": false,
  "platform": {
    "type": "baremetal"
   },
  "cluster_networks": [
    {
      "cidr": "10.128.0.0/14",
      "host_prefix": 23
    }
  ],
  "service_networks": [
    {
      "cidr": "172.31.0.0/16"
    }
  ],
  "machine_networks": [
    {
      "cidr": "${CLUSTER_MACHINE_NETWORK}"
    }
  ],
  "network_type": "${CLUSTER_OVN}",
  "additional_ntp_source": "${NTP_SOURCE}",
  "vip_dhcp_allocation": false,      
  "ssh_public_key": "$CLUSTER_SSHKEY",
  "pull_secret": $PULL_SECRET
}
EOF
}


echo "Setting API and Ingress VIPs..."

SET_HOST_INFO_REQ=$(curl -s \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--request POST \
--data "$(generatePatchData)" \
"https://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters")

printf '%s' "$SET_HOST_INFO_REQ" | python3 -m json.tool
CLUSTER_ID=$(curl -s -X GET "https://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v2/clusters?with_hosts=true" --header "Authorization: Bearer $ACTIVE_TOKEN" -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].id')
echo $CLUSTER_ID > ~/$CLUSTER_ID.txt
echo "Cluster ID"
cat ~/$CLUSTER_ID.txt


