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



NODE_LENGTH=$(echo "${NODE_CFGS}" | jq -r '.nodes[].name' | wc -l)
if [ ${NODE_LENGTH} -eq 1 ]; then
  CP_CPU_CORES="8"
  CP_RAM_GB="32"
  CP_CPU_SOCKETS="1"
  DISK_SIZE="130"
  LIBVIRT_VM_PATH="/var/lib/libvirt/images"
else
  CP_CPU_CORES="4"
  CP_RAM_GB="16"
  CP_CPU_SOCKETS="1"
  DISK_SIZE="130"
  LIBVIRT_VM_PATH="/var/lib/libvirt/images"
fi

# uncomment POWEROFF if RHEL 8.5 or less
# POWEROFF=",on_poweroff=preserve"
if [ ! -f ${LIBVIRT_VM_PATH}/ai-liveiso-$CLUSTER_ID.iso ];
then 
  sudo cp ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso  ${LIBVIRT_VM_PATH}/ai-liveiso-$CLUSTER_ID.iso 
fi 

if [ ! -z ${NEW_CLUSTER_ID} ] &&  [ ! -f ${LIBVIRT_VM_PATH}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso ];
then 
  if [ ! -f ${LIBVIRT_VM_PATH}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso ];
  then 
    sudo cp ${CLUSTER_DIR}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso  ${LIBVIRT_VM_PATH}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso 
  fi 
fi 

array=(  containerLANbr0 qubibr0 )
for i in "${array[@]}"
do
  echo "checking for $i"
  INTERFACE=$(ip addr | grep -oE $i | head -1)
  BOND_INTERFACE=$(ip addr | grep -oE bond0 | head -1)
  INTERNAL_INTERFACE=$(ip addr | grep -oE internal-net | head -1)
  if [ $DISCONNECTED_INSTALL == "true" ] || [ $SELF_HOSTED_INSTALLER == "true" ];
  then
    LIBVIRT_NETWORK="network=bare-net,model=virtio"
    break
  elif [[ ${INTERFACE} == 'containerLANbr0' ]];
  then 
    LIBVIRT_NETWORK="bridge=containerLANbr0,model=virtio"
    break
  elif  [[ ${INTERFACE} == 'qubibr0' ]];
  then
    LIBVIRT_NETWORK="bridge=qubibr0,model=virtio"
    break
  elif [[ ${INTERNAL_INTERFACE} == 'internal-net' ]];
  then
    LIBVIRT_NETWORK_TWO="network=internal-net,model=virtio"
    LIBVIRT_NETWORK="network=default,model=virtio"
    break
  elif [[ ! -z $BOND_INTERFACE ]]
  then
    LIBVIRT_NETWORK="network=default,model=virtio"
    break
  else
    echo "${array[@]}  not found please machine with one of the interfaces"
  fi
done

if [ ! -z ${NEW_CLUSTER_ID} ];
then 
  echo "Adding  New worker  to cluster  ${NEW_CLUSTER_ID}"

  if [ $MULTI_NETWORK  == false ]; then 
    LIBVIRT_LIKE_OPTIONS="--connect=qemu:///system -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso    --os-variant=fedora-coreos-stable --events on_reboot=restart${POWEROFF} --graphics vnc,listen=0.0.0.0,tlsport=,defaultMode='insecure' --network ${LIBVIRT_NETWORK} --console pty,target_type=serial"
  elif [ $MULTI_NETWORK  == true ]; then 
    LIBVIRT_LIKE_OPTIONS="--connect=qemu:///system -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/ai-liveiso-addhosts-$NEW_CLUSTER_ID.iso     --os-variant=fedora-coreos-stable --events on_reboot=restart${POWEROFF} --graphics vnc,listen=0.0.0.0,tlsport=,defaultMode='insecure' --network ${LIBVIRT_NETWORK}  --console pty,target_type=serial"
  fi 

else
  if [ $MULTI_NETWORK  == false ]; then 
    LIBVIRT_LIKE_OPTIONS="--connect=qemu:///system -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/ai-liveiso-$CLUSTER_ID.iso   --os-variant=fedora-coreos-stable --events on_reboot=restart${POWEROFF} --graphics vnc,listen=0.0.0.0,tlsport=,defaultMode='insecure' --network ${LIBVIRT_NETWORK} --console pty,target_type=serial"
  elif [ $MULTI_NETWORK  == true ]; then 
    LIBVIRT_LIKE_OPTIONS="--connect=qemu:///system -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/ai-liveiso-$CLUSTER_ID.iso   --os-variant=fedora-coreos-stable --events on_reboot=restart${POWEROFF} --graphics vnc,listen=0.0.0.0,tlsport=,defaultMode='insecure' --network ${LIBVIRT_NETWORK} --console pty,target_type=serial"
  fi 
fi 

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
    if [ $MULTI_NETWORK  == false ]; then 
      nohup sudo virt-install ${LIBVIRT_LIKE_OPTIONS} --mac="$(_jq '.mac_address')" --name=${CLUSTER_NAME}-$(_jq '.name') --vcpus "sockets=${CP_CPU_SOCKETS},cores=${CP_CPU_CORES},threads=1" --memory="$(expr ${CP_RAM_GB} \* 1024)" --disk "size=${DISK_SIZE},path=${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2,cache=none,format=qcow2" &
    elif [ $MULTI_NETWORK  == true ]; then 
      #nohup sudo virt-install ${LIBVIRT_LIKE_OPTIONS} --mac="$(_jq '.mac_address_int1')" --mac="$(_jq '.mac_address_int2')" --name=${CLUSTER_NAME}-$(_jq '.name') --vcpus "sockets=${CP_CPU_SOCKETS},cores=${CP_CPU_CORES},threads=1" --memory="$(expr ${CP_RAM_GB} \* 1024)" --disk "size=${DISK_SIZE},path=${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2,cache=none,format=qcow2" &
      sudo virt-install -n ${CLUSTER_NAME}-$(_jq '.name')  --memory="$(expr ${CP_RAM_GB} \* 1024)" \
        --disk "size=${DISK_SIZE},path=${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2,cache=none,format=qcow2" \
        --cdrom=${LIBVIRT_VM_PATH}/ai-liveiso-$CLUSTER_ID.iso \
        --network ${LIBVIRT_NETWORK},mac=$(_jq '.mac_address_int1') \
        --network ${LIBVIRT_NETWORK_TWO},mac=$(_jq '.mac_address_int2') \
        --connect=qemu:///system -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi \
        --graphics vnc,listen=0.0.0.0 --noautoconsole -v --vcpus "sockets=${CP_CPU_SOCKETS},cores=${CP_CPU_CORES},threads=1"
      #echo sudo virt-install ${LIBVIRT_LIKE_OPTIONS} --mac="$(_jq '.mac_address_int1')" --network ${LIBVIRT_NETWORK} --mac="$(_jq '.mac_address_int2')" --name=${CLUSTER_NAME}-$(_jq '.name') --vcpus "sockets=${CP_CPU_SOCKETS},cores=${CP_CPU_CORES},threads=1" --memory="$(expr ${CP_RAM_GB} \* 1024)" --disk "size=${DISK_SIZE},path=${LIBVIRT_VM_PATH}/${CLUSTER_NAME}-$(_jq '.name').qcow2,cache=none,format=qcow2"
    fi 
    sleep 3
  else
    echo "  VM $(_jq '.name') already exists ..."
  fi

done