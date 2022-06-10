#!/bin/bash

echo -e "\n[INFO] Creating the disk images for the OpenShift nodes...\n"

for i in master1 master2 master3 worker1 worker2 worker3
do
	sudo qemu-img create -f qcow2 /var/lib/libvirt/images/ocp4-$i.qcow2 120G
done

WORKER_MEMORY=32768
MASTER_MEMORY=16384
MASTER_CPU=4
CPU_FLAGS="--cpu=host-passthrough"
NETWORK="ztpfw"
OS_VARIANT="rhel8.5"
LIBVIRT_VM_PATH="/var/lib/libvirt/images"

sudo virt-install --virt-type kvm --ram $MASTER_MEMORY --vcpus $MASTER_CPU --os-variant ${OS_VARIANT} --disk path=/var/lib/libvirt/images/ocp4-master1.qcow2,device=disk,bus=virtio,format=qcow2 $CPU_FLAGS --noautoconsole --network network:${NETWORK},mac=52:54:00:e7:05:72 --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/agent.iso --name ocp4-master1 --print-xml 1 > ocp4-master1.xml
sudo virt-install --virt-type kvm --ram $MASTER_MEMORY --vcpus $MASTER_CPU --os-variant ${OS_VARIANT} --disk path=/var/lib/libvirt/images/ocp4-master2.qcow2,device=disk,bus=virtio,format=qcow2 $CPU_FLAGS --noautoconsole --network network:${NETWORK},mac=52:54:00:95:fd:f3 --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/agent.iso --name ocp4-master2 --print-xml 1 > ocp4-master2.xml
sudo virt-install --virt-type kvm --ram $MASTER_MEMORY --vcpus $MASTER_CPU --os-variant ${OS_VARIANT} --disk path=/var/lib/libvirt/images/ocp4-master3.qcow2,device=disk,bus=virtio,format=qcow2 $CPU_FLAGS --noautoconsole --network network:${NETWORK},mac=52:54:00:e8:b9:18 --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_VM_PATH}/agent.iso --name ocp4-master3 --print-xml 1 > ocp4-master3.xml
sudo virsh define ocp4-master1.xml 
sudo virsh define ocp4-master2.xml 
sudo virsh define ocp4-master3.xml
