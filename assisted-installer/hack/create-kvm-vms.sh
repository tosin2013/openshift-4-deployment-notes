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

CP_CPU_CORES="4"
CP_RAM_GB="16"
CP_CPU_SOCKETS="1"
DISK_SIZE="130"
LIBVIRT_VM_PATH="/var/lib/libvirt/images"
LIBVIRT_NETWORK="bridge=containerLANbr0,model=virtio"
LIBVIRT_LIKE_OPTIONS="--connect=qemu:///system -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi --cdrom=${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso --os-variant=fedora-coreos-stable --events on_reboot=restart,on_poweroff=preserve --graphics vnc,listen=0.0.0.0,tlsport=,defaultMode='insecure' --network ${LIBVIRT_NETWORK} --console pty,target_type=serial"

#########################################################
## Check to see if all the nodes have reported in

echo -e "===== Creating OpenShift Libvirt Infrastructure..."

## Loop through defined nodes, match to this node if applicable
for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }

  ## See if the disk image already exists
  if [[ -f "${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2" ]]; then
    echo -e "  Disk for $(_jq '.name') already exists on host at ${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2 ..."
  else
    echo "  Creating disk for VM $(_jq '.name') at ${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2 ..."
    sudo qemu-img create -f qcow2 ${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2 ${DISK_SIZE}G
  fi

  ## Check to see if the VM exists
  VIRSH_VM=$(sudo virsh list --all | grep ${CLUSTER_NAME}-$(_jq '.name') || true);
  if [[ -z "${VIRSH_VM}" ]]; then
    echo "  Creating VM $(_jq '.name') ..."
    nohup sudo virt-install ${LIBVIRT_LIKE_OPTIONS} --mac="$(_jq '.mac_address')" --name=${CLUSTER_NAME}-$(_jq '.name') --vcpus "sockets=${CP_CPU_SOCKETS},cores=${CP_CPU_CORES},threads=1" --memory="$(expr ${CP_RAM_GB} \* 1024)" --disk "size=${DISK_SIZE},path=${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2,cache=none,format=qcow2" &
    sleep 3
  else
    echo "  VM $(_jq '.name') already exists ..."
  fi

done