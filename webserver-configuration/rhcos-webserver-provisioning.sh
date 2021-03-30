#!/bin/bash
set -xe

function nightly() {
  # https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/
  OC_VERSION="rhcos-4.7.0-rc.2"
  RELEASE="pre-release"
  VERSION="latest"
  sudo mkdir -p /var/lib/tftpboot/openshift4/${OC_VERSION}
  cd /var/lib/tftpboot/openshift4/${OC_VERSION}
  sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RELEASE}/${VERSION}/rhcos-live-kernel-x86_64
  sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RELEASE}/${VERSION}/rhcos-live-initramfs.x86_64.img
  sudo restorecon -RFv .

  sudo mkdir -p /var/www/html/openshift4/${OC_VERSION}/images/
  sudo chown root:apache -R /var/www/html/openshift4/
  sudo chmod 775 -R /var/www/html/openshift4/

  cd  /var/www/html/openshift4/${OC_VERSION}/images/
  sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RELEASE}/${VERSION}/rhcos-metal.x86_64.raw.gz
  sudo restorecon -RFv .
}

function general_release() {
  # https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/
  OC_VERSION="4.7.0"
  VERSION="latest"
  sudo mkdir -p /var/lib/tftpboot/openshift4/${OC_VERSION}
  cd /var/lib/tftpboot/openshift4/${OC_VERSION}
  sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${VERSION}/${OC_VERSION}/rhcos-live-kernel-x86_64
  sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${VERSION}/${OC_VERSION}/rhcos-live-initramfs.x86_64.img
  sudo restorecon -RFv .

  sudo mkdir -p /var/www/html/openshift4/${OC_VERSION}/images/
  sudo chown root:apache -R /var/www/html/openshift4/
  sudo chmod 775 -R /var/www/html/openshift4/

  cd  /var/www/html/openshift4/${OC_VERSION}/images/
  sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${VERSION}/${OC_VERSION}/rhcos-metal.x86_64.raw.gz
  sudo restorecon -RFv .
}

function main() {
  if [[ -z $1 ]]; then
    echo "Please pass release version."
    echo "Usage: $0 ga or  $0 nightly"
    exit 1
  fi

  if [[ $1 == "ga" ]]; then
    general_release
  elif [[ $1 == "nightly" ]]; then
    nightly
  else
    echo "Incorrect flag passed"
    exit 1
  fi
}


main $1
