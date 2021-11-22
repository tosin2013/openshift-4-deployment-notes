#!/bin/bash

set -e

echo -e "\n===== Setting cluster networking..."

generatePatchData() {
cat <<EOF
{
  "vip_dhcp_allocation": false,
  "api_vip": "${CLUSTER_API_VIP}",
  "ingress_vip": "${CLUSTER_INGRESS_VIP}",
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
"${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID")

if [ -z "$SET_HOST_INFO_REQ" ]; then
  echo "ERROR: Failed to set cluster networking information"
  exit 1
fi

# printf '%s' "$SET_HOST_INFO_REQ" | python3 -m json.tool