#!/bin/bash
set -xe
# on PXE NODE 
#sudo systemctl stop dhcpd
#sudo systemctl status dhcpd

# on HA PROXY NODE
#sudo systemctl stop haproxy
#sudo systemctl status haproxy

source oc-env
args='nomodeset '
args+='coreos.inst=yes '
args+='coreos.inst.install_dev=vda '
args+='coreos.inst.image_url=http://'${WEB_SERVER}':8080/openshift4/'${OC_VERSION}'/images/rhcos-'${BUILD_VERSION}'-metal-bios.raw.gz '
args+='coreos.inst.ignition_url=http://'${WEB_SERVER}':8080/openshift4/'${OC_VERSION}'/ignitions/bootstrap.ign '
args+='rd.neednet=1'

# BootStrap Node
echo "**************************"
echo "* Deploy BootStrap Nodes *"
echo "**************************"
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/bootstrap.qcow2 120G
sudo virt-format --format=qcow2 -a /var/lib/libvirt/images/bootstrap.qcow2 

sudo virt-install --name bootstrap \
  --disk /var/lib/libvirt/images/bootstrap.qcow2 --memory 16192 --vcpus 4 \
  --os-type linux --os-variant rhel7 \
  --network network=${KVM_NETWORK},model=e1000 --noreboot --noautoconsole\
  --location /home/admin/qubinode-installer/rhcos-install/${OC_VERSION} \
  --extra-args="${args}"

sleep 30s

unset args

# Three Masters 
echo "******************************"
echo "* Deploy Three Masters Nodes *"
echo "******************************"
for i in {1..3}
do 
    args='nomodeset '
    args+='coreos.inst=yes '
    args+='coreos.inst.install_dev=vda '
    args+='coreos.inst.image_url=http://'${WEB_SERVER}':8080/openshift4/'${OC_VERSION}'/images/rhcos-'${BUILD_VERSION}'-metal-bios.raw.gz '
    args+='coreos.inst.ignition_url=http://'${WEB_SERVER}':8080/openshift4/'${OC_VERSION}'/ignitions/master.ign '
    args+='rd.neednet=1'

    sudo qemu-img create -f qcow2  /var/lib/libvirt/images/master-0${i}.qcow2 120G
    sudo virt-format --format=qcow2 -a /var/lib/libvirt/images/master-0${i}.qcow2
    sudo virt-install --name master-0${i} \
    --disk /var/lib/libvirt/images/master-0${i}.qcow2 --memory 16192 --vcpus 4 \
    --os-type linux --os-variant rhel7 \
    --network network=${KVM_NETWORK},model=e1000 --noreboot --noautoconsole\
    --location /home/admin/qubinode-installer/rhcos-install/${OC_VERSION} \
    --extra-args="${args}"
    sleep 5s
done 

sleep 30s

unset args

# Two Workers
echo "******************************"
echo "* Deploy Two Workers Nodes *"
echo "******************************"
for i in {1..2}
do 

    args='nomodeset '
    args+='coreos.inst=yes '
    args+='coreos.inst.install_dev=vda '
    args+='coreos.inst.image_url=http://'${WEB_SERVER}':8080/openshift4/'${OC_VERSION}'/images/rhcos-'${BUILD_VERSION}'-metal-bios.raw.gz '
    args+='coreos.inst.ignition_url=http://'${WEB_SERVER}':8080/openshift4/'${OC_VERSION}'/ignitions/worker.ign '
    args+='rd.neednet=1'

    sudo qemu-img create -f qcow2  /var/lib/libvirt/images/worker-0${i}.qcow2 120G
    sudo virt-format --format=qcow2 -a /var/lib/libvirt/images/worker-0${i}.qcow2 
    sudo virt-install --name worker-0${i} \
    --disk /var/lib/libvirt/images/worker-0${i}.qcow2 --memory 8192 --vcpus 4 \
    --os-type linux --os-variant rhel7 \
    --network network=${KVM_NETWORK},model=e1000 --noreboot --noautoconsole\
    --location /home/admin/qubinode-installer/rhcos-install/${OC_VERSION} \
    --extra-args="${args}"
    sleep 5s
done 

sleep 30s