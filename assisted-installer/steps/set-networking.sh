#!/bin/bash
set -e

source cluster-vars.sh
source authenticate-to-api.sh

if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
fi

echo -e "\n===== Setting cluster networking..."

generatePatchData() {
cat <<EOF
{
  "vip_dhcp_allocation": false,
  "api_vips": [
    {
      "cluster_id": "${TARGET_CLUSTER_ID}",
      "ip": "${CLUSTER_API_VIP}"
    }
  ],
  "ingress_vips": [
    {
      "cluster_id": "${TARGET_CLUSTER_ID}",
      "ip": "${CLUSTER_INGRESS_VIP}"
    }
  ],
  "user_managed_networking": false
}
EOF
}

SET_HOST_INFO_REQ=$(curl -s --fail \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request PATCH \
  --data "$(generatePatchData)" \
"${ASSISTED_SERVICE_V2_API}/clusters/$TARGET_CLUSTER_ID")

if [ -z "$SET_HOST_INFO_REQ" ]; then
  echo "ERROR: Failed to set cluster networking information"
  exit 1
fi

# printf '%s' "$SET_HOST_INFO_REQ" | python3 -m json.tool