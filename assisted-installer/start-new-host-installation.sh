#!/bin/bash

set -e

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

#########################################################
## Perform preflight checks
source $SCRIPT_DIR/preflight.sh

if [ -z "$CLUSTER_ID" ]; then
  echo -e "\n===== No Cluster ID found! Run ./bootstrap-create.sh first!\n"
  exit 1
else
  echo -e "===== Cluster ID: $CLUSTER_ID\n"
fi

if [ -z "$NEW_CLUSTER_ID" ]; then
  echo -e "\n===== No New Cluster ID found! Run ./bootstrap-scale-up.sh first!\n"
  exit 1
else
  echo -e "===== New Cluster ID: $NEW_CLUSTER_ID\n"
fi

if [ -z "$NEW_INFRAENV_ID" ]; then
  echo -e "\n===== No New InfraEnv ID found! Run ./bootstrap-scale-up.sh first!\n"
  exit 1
else
  echo -e "===== New InfraEnv ID: $NEW_INFRAENV_ID\n"
fi


#########################################################
## Query the API for new hosts
CLUSTER_INFO_REQ=$(curl -s \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request GET \
"${ASSISTED_SERVICE_V2_API}/clusters/$NEW_CLUSTER_ID")

#echo $CLUSTER_INFO_REQ | python3 -m json.tool

NEW_HOSTS=$(echo $CLUSTER_INFO_REQ | jq '{
    "hosts":
        [
          .hosts[]
          | select(.status != "installed")
          | {id, requested_hostname, role, status, status_info, progress, status_updated_at, updated_at, infra_env_id, cluster_id, created_at, inventory}
        ]
      }')

#echo $NEW_HOSTS | python3 -m json.tool

NEW_HOST_IDS=($(echo $CLUSTER_INFO_REQ |  jq -r '.hosts[] | .id'))

for i in "${NEW_HOST_IDS[@]}"; 
do :
  echo " - Found new host:  ${i}: "
done

echo ""
read -p "===== Begin the host(s) installation? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  
  echo -e "\n"

  for node in $(echo "${NEW_HOSTS}" | jq -r '.hosts[] | @base64'); do
    _jq() {
      echo ${node} | base64 --decode | jq -r ${1}
    }
    #echo " - Processing HostID: $(_jq '.id') - Hostname: $(_jq '.requested_hostname') - Role: $(_jq '.role') - Status: $(_jq '.status') - Progress: $(_jq '.progress')"
    echo " - Processing HostID: $(_jq '.id') - Hostname: $(_jq '.requested_hostname') - Role: $(_jq '.role') - Status: $(_jq '.status')"
    
    if [ "$(_jq '.progress.stage_started_at')" == "0001-01-01T00:00:00.000Z" ]; then

      if [ "$(_jq '.status')" == "installing" ]; then
        echo "   This node is already installing. Skipping...wait a while and look for a new Node and CSR to approve in the OpenShift cluster dashboard."
      else

        HOST_INVENTORY=$(_jq '.inventory')
        echo "   MAC Address(es): $(echo $HOST_INVENTORY | jq -r '.interfaces[] | .mac_address')"
        read -p "   Enter node hostname > " HOST_HOSTNAME

        HOST_NODE=$(echo $NODE_CFGS | jq -r --arg hostname "$HOST_HOSTNAME" '.nodes[] | select(.name == $hostname)')
        HOST_NAME=$(echo $HOST_NODE | jq -r '.name')
        HOST_ROLE=$(echo $HOST_NODE | jq -r '.role')
        HOST_ID=$(_jq '.id')

        if [ -z "$HOST_NAME" ]; then
          echo "   No matching hostname/node definition found for $HOST_HOSTNAME"
          exit 1
        else
          echo "   Matched to defined $HOST_NAME as a $HOST_ROLE node"

          echo "   Updating hostname to $HOST_NAME..."
          SET_NAME_INFO_REQ=$(curl -s -o /dev/null -w "%{http_code}" \
            --header "Authorization: Bearer $ACTIVE_TOKEN" \
            --header "Content-Type: application/json" \
            --header "Accept: application/json" \
            --request PATCH \
            --data-raw '{ "host_name": "'${HOST_NAME}'"}' \
            "${ASSISTED_SERVICE_V2_API}/infra-envs/${NEW_INFRAENV_ID}/hosts/${HOST_ID}")

          if [ "$SET_NAME_INFO_REQ" != "201" ]; then
            echo "===== Failed to configure host names and roles! ERROR CODE: $SET_NAME_INFO_REQ"
            exit 1
          fi

          echo "   Updating host role to $HOST_ROLE..."
          if [ "$HOST_ROLE" == "application-node" ]; then
            ROLE="worker"
          else
            ROLE="master"
          fi

          SET_ROLE_INFO_REQ=$(curl -s -o /dev/null -w "%{http_code}" \
            --header "Authorization: Bearer $ACTIVE_TOKEN" \
            --header "Content-Type: application/json" \
            --header "Accept: application/json" \
            --request PATCH \
            --data-raw '{ "host_role": "'${ROLE}'"}' \
            "${ASSISTED_SERVICE_V2_API}/infra-envs/${NEW_INFRAENV_ID}/hosts/${HOST_ID}")

          if [ "$SET_ROLE_INFO_REQ" != "201" ]; then
            echo "===== Failed to configure host names and roles! ERROR CODE: $SET_ROLE_INFO_REQ"
            exit 1
          fi

          echo -e "   Installing host..."
          INSTALL_HOST_REQ=$(curl -s \
            --header "Authorization: Bearer $ACTIVE_TOKEN" \
            --header "Content-Type: application/json" \
            --header "Accept: application/json" \
            --request POST \
          "${ASSISTED_SERVICE_V2_API}/infra-envs/$NEW_INFRAENV_ID/hosts/$HOST_ID/actions/install")
        fi
      fi

    else
      echo "   Host is already installed!  Check the cluster for new Nodes and CSRs to approve"
    fi

    echo ""
  done

else
  echo -e "\n\n===== Skipping host installation\n"
  exit 1
fi