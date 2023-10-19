#!/bin/bash

DEPLOY_TYPE=$1

create_vm() {
	local NAME=$1
	local MEMORY=$2
	local CPU=$3
	local MAC=$4
	local DISK_PATH="/var/lib/libvirt/images/ocp4-$NAME.qcow2"

	sudo qemu-img create -f qcow2 $DISK_PATH 120G
	sudo virt-install --virt-type kvm --ram $MEMORY --vcpus $CPU --os-variant ${OS_VARIANT} --disk path=$DISK_PATH,device=disk,bus=virtio,format=qcow2 $CPU_FLAGS --noautoconsole --network network:${NETWORK},mac=$MAC --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/agent.x86_64.iso --name ocp4-$NAME --print-xml 1 > ocp4-$NAME.xml
	sudo virsh define ocp4-$NAME.xml 
}

WORKER_MEMORY=32768
MASTER_MEMORY=16384
MASTER_CPU=4
CPU_FLAGS="--cpu=host-passthrough"
NETWORK="default"
# osinfo-query os
OS_VARIANT="rhel8.7"
LIBVIRT_VM_PATH="/var/lib/libvirt/images"

case "$DEPLOY_TYPE" in
	"sno")
		echo -e "\n[INFO] Creating the disk image for the OpenShift node 'sno'...\n"
		create_vm "sno" 65536 16 "52:54:00:e7:05:72"
		;;

	"converged")
		echo -e "\n[INFO] Creating the disk images for the OpenShift converged nodes...\n"
		create_vm "master1" $MASTER_MEMORY $MASTER_CPU "52:54:00:e7:05:72"
		create_vm "master2" $MASTER_MEMORY $MASTER_CPU "52:54:00:95:fd:f3"
		create_vm "master3" $MASTER_MEMORY $MASTER_CPU "52:54:00:e8:b9:18"
		;;

	"standard")
		echo -e "\n[INFO] Creating the disk images for the OpenShift standard nodes...\n"
		create_vm "master1" $MASTER_MEMORY $MASTER_CPU "52:54:00:e7:05:72"
		create_vm "master2" $MASTER_MEMORY $MASTER_CPU "52:54:00:95:fd:f3"
		create_vm "master3" $MASTER_MEMORY $MASTER_CPU "52:54:00:e8:b9:18"
		create_vm "worker1" $WORKER_MEMORY $MASTER_CPU "52:54:00:a7:b5:74"  # Modify MAC addresses accordingly
		create_vm "worker2" $WORKER_MEMORY $MASTER_CPU "52:54:00:b6:c4:85"  # Modify MAC addresses accordingly
		create_vm "worker3" $WORKER_MEMORY $MASTER_CPU "52:54:00:c5:d3:96"  # Modify MAC addresses accordingly
		;;

	*)
		echo "Invalid deployment type. Please choose between 'sno', 'converged', or 'standard'."
		exit 1
		;;
esac
