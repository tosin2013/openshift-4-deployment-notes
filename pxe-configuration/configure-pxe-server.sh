#!/bin/bash
set -xe
if [[ ! -f oc-env ]]; then
  echo "Failed to find oc-env"
  exit 1
fi

source oc-env

mkdir -pv  /var/lib/tftpboot/pxelinux.cfg
cat >/var/lib/tftpboot/pxelinux.cfg/default<<EOF
default menu.c32
prompt 0
timeout 30
menu title **** OpenShift 4 PXE Boot Menu ****

label Install CoreOS ${OC_VERSION} Bootstrap Node
 kernel /openshift4/${OC_VERSION}/rhcos-${BUILD_VERSION}-installer-kernel
 append ip=dhcp rd.neednet=1 coreos.inst.install_dev=vda console=tty0 console=ttyS0 coreos.inst=yes coreos.inst.image_url=http://${WEBSERVER}:8080/openshift4/${OC_VERSION}/images/rhcos-metal.x86_64.raw.gz coreos.inst.ignition_url=http://${WEBSERVER}:8080/openshift4/${OC_VERSION}/ignitions/bootstrap.ign initrd=/openshift4/${OC_VERSION}/rhcos-live-initramfs.x86_64.img

label Install CoreOS ${OC_VERSION} Master Node
 kernel /openshift4/${OC_VERSION}/rhcos-${BUILD_VERSION}-installer-kernel
 append ip=dhcp rd.neednet=1 coreos.inst.install_dev=vda console=tty0 console=ttyS0 coreos.inst=yes coreos.inst.image_url=http://${WEBSERVER}:8080/openshift4/${OC_VERSION}/images/rhcos-metal.x86_64.raw.gz coreos.inst.ignition_url=http://${WEBSERVER}:8080/openshift4/${OC_VERSION}/ignitions/master.ign initrd=/openshift4/${OC_VERSION}/rhcos-live-initramfs.x86_64.img

label Install CoreOS ${OC_VERSION} Worker Node

 kernel /openshift4/${OC_VERSION}/rhcos-${BUILD_VERSION}-installer-kernel
 append ip=dhcp rd.neednet=1 coreos.inst.install_dev=vda console=tty0 console=ttyS0 coreos.inst=yes coreos.inst.image_url=http://${WEBSERVER}:8080/openshift4/${OC_VERSION}/images/rhcos-metal.x86_64.raw.gz coreos.inst.ignition_url=http://${WEBSERVER}:8080/openshift4/${OC_VERSION}/ignitions/worker.ign initrd=/openshift4/${OC_VERSION}/rhcos-live-initramfs.x86_64.img
EOF

cat /var/lib/tftpboot/pxelinux.cfg/default

sleep 5s

cp -rvf /usr/share/syslinux/* /var/lib/tftpboot

systemctl start tftp

systemctl status tftp
