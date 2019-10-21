#!/bin/bash
set -xe

source oc-env
sudo mkdir -p /home/admin/qubinode-installer/rhcos-install/${OC_VERSION}
cd /home/admin/qubinode-installer/rhcos-install/${OC_VERSION}
sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RELEASE}/${VERSION}/rhcos-${BUILD_VERSION}-installer-kernel 
sudo cp rhcos-${BUILD_VERSION}-installer-kernel vmlinuz
sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RELEASE}/${VERSION}/rhcos-${BUILD_VERSION}-installer-initramfs.img
sudo cp rhcos-${BUILD_VERSION}-installer-initramfs.img initramfs.img
sudo cat <<EOF > /home/admin/qubinode-installer/rhcos-install/${OC_VERSION}/.treeinfo
[general]
arch = x86_64
family = Red Hat CoreOS
platforms = x86_64
version = 4.2.0-0
[images-x86_64]
initrd = initramfs.img
kernel = vmlinuz
EOF