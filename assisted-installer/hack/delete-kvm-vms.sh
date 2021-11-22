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

LIBVIRT_VM_PATH="/var/lib/libvirt/images"

#########################################################
## Check to see if all the nodes have reported in

echo -e "===== Deleting OpenShift Libvirt Infrastructure..."

## Loop through defined nodes, match to this node if applicable
for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }

  ## Check to see if the VM exists
  VIRSH_VM=$(sudo virsh list --all | grep ${CLUSTER_NAME}-$(_jq '.name') || true);
  if [[ ! -z "${VIRSH_VM}" ]]; then
    echo "  Deleting VM $(_jq '.name') ..."
    sudo virsh shutdown ${CLUSTER_NAME}-$(_jq '.name') || true
    sudo virsh undefine ${CLUSTER_NAME}-$(_jq '.name') || true
  fi

  ## See if the disk image exists
  if [[ -f "${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2" ]]; then
    echo "  Deleting disk for VM $(_jq '.name') at ${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2 ..."
    sudo rm ${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2 || true
  fi

done