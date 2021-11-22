#!/bin/bash

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
fi

# Make an array
VM_ARR=()

## Loop through defined nodes, set as a named array
for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }
  VM_ARR+=("${CLUSTER_NAME}-$(_jq '.name')")
done

LOOP_ON="true"
VIRSH_WATCH_CMD="sudo virsh list --state-shutoff --name"

echo "===== Watching virsh to reboot Cluster VMs: ${VM_ARR[@]}"

while [ $LOOP_ON = "true" ]; do
  currentPoweredOffVMs=$($VIRSH_WATCH_CMD)

  # loop through VMs that are powered off
  while IFS="" read -r p || [ -n "$p" ]
  do
    if [[ " ${VM_ARR[@]} " =~ " ${p} " ]]; then
      # Powered off VM matches the original list of VMs, turn it on and remove from array
      echo "  Starting VM: ${p} ..."
      sudo virsh start $p
      # Remove from original array
      TMP_ARR=()
      for val in "${VM_ARR[@]}"; do
        [[ $val != $p ]] && TMP_ARR+=($val)
      done
      VM_ARR=("${TMP_ARR[@]}")
      unset TMP_ARR
    fi
  done < <(printf '%s' "${currentPoweredOffVMs}")

  if [ '0' -eq "${#VM_ARR[@]}" ]; then
    LOOP_ON="false"
    echo "  All Cluster VMs have been restarted!"
  else
    echo "  Still waiting on ${#VM_ARR[@]} VMs: ${VM_ARR[@]}"
    sleep 10
  fi
done