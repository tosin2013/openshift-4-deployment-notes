#!/bin/bash

set -e

echo -e "\n===== Getting cluster hosts that have been installed..."

# Query the Cluster for Information around its composition
CLUSTER_INFO_REQ=$(curl -s \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request GET \
"${ASSISTED_SERVICE_V2_API}/clusters/$CLUSTER_ID")

#echo $CLUSTER_INFO_REQ | python3 -m json.tool

CURRENT_HOSTS=()
CURRENT_HOSTS_COUNT=0
INSTALLED_HOSTS=()
INSTALLED_HOSTS_COUNT=0
DEFINED_HOSTS=()
DEFINED_HOSTS_COUNT=0
MATCHED_HOSTS=()
MATCHED_HOSTS_COUNT=0
UNMATCHED_HOSTS=()
UNMATCHED_HOSTS_COUNT=0

## Loop through defined nodes, create arrays of current and installed hosts
for node in $(echo "${CLUSTER_INFO_REQ}" | jq -r '.hosts[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }

  CURRENT_HOSTS+=("$(_jq '.requested_hostname')")
  CURRENT_HOSTS_COUNT=$((CURRENT_HOSTS_COUNT+1))
  if [ "$(_jq '.status')" == "installed" ]; then
    INSTALLED_HOSTS+=("$(_jq '.requested_hostname')")
    INSTALLED_HOSTS_COUNT=$((INSTALLED_HOSTS_COUNT+1))
  fi

done

echo "CURRENT_HOSTS: ${CURRENT_HOSTS[@]}"
echo "CURRENT_HOSTS_COUNT: ${CURRENT_HOSTS_COUNT[@]}"
echo "INSTALLED_HOSTS: ${INSTALLED_HOSTS[@]}"
echo "INSTALLED_HOSTS_COUNT: ${INSTALLED_HOSTS_COUNT[@]}"

echo -e "\n===== Comparing with defined hosts..."

## Loop through defined nodes, match to this node if applicable
for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }
  DEFINED_HOSTS+=("$(_jq '.name')")
  DEFINED_HOSTS_COUNT=$((DEFINED_HOSTS_COUNT+1))
  if [[ " ${CURRENT_HOSTS[*]} " =~ " $(_jq '.name') " ]]; then
    MATCHED_HOSTS+=("$(_jq '.name')")
    MATCHED_HOSTS_COUNT=$((MATCHED_HOSTS_COUNT+1))
  else
    export UNMATCHED_HOSTS+=("$(_jq '.name')")
    export UNMATCHED_HOSTS_COUNT=$((MATCHED_HOSTS_COUNT+1))
  fi
done

## Check if the current hosts are equal to the defined hosts
if [ $CURRENT_HOSTS_COUNT -eq $DEFINED_HOSTS_COUNT ]; then
  ## Check if the installed hosts are equal to the defined hosts
  if [ $INSTALLED_HOSTS_COUNT -eq $DEFINED_HOSTS_COUNT ]; then
    echo "  All defined hosts are installed!"
    export CLUSTER_ALL_HOSTS_INSTALLED="true"
    export CLUSTER_ALL_HOSTS_REPORTED="true"
  else
    echo "  All hosts are defined but not installed - proceeding to check for cluster installation..."
    export CLUSTER_ALL_HOSTS_INSTALLED="false"
    export CLUSTER_ALL_HOSTS_REPORTED="true"
  fi
else
  echo "  New hosts defined!  Proceeding with scaling action..."
  export CLUSTER_ALL_HOSTS_INSTALLED="false"
  export CLUSTER_ALL_HOSTS_REPORTED="false"
fi