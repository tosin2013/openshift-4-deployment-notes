#!/bin/bash
set -xe

VERSION="4.2.0"
RELEASE="latest"
URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/"
#OC_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/${RELEASE}/  | grep -o openshift-install-linux-${VERSION}.tar.gz | head -1)
OC_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/ | grep -oE openshift-install-linux-${VERSION}"(.*)".tar.gz | cut -d'"' -f2  | tr -d '>')

wget ${URL}${OC_INSTALLER}
sudo tar zxvf ${OC_INSTALLER} -C /usr/local/bin
sudo rm -f ${OC_INSTALLER}
sudo chmod +x /usr/local/bin/openshift-install 
openshift-install version

OC_CLI_CLIENT=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/  | grep -oE 	openshift-client-linux-${VERSION}"(.*)".tar.gz | cut -d'"' -f2  | tr -d '>')
wget ${URL}${OC_CLI_CLIENT}
sudo tar zxvf ${OC_CLI_CLIENT} -C /usr/local/bin
sudo rm -f ${OC_CLI_CLIENT}
sudo chmod +x /usr/local/bin/oc
oc version

sudo oc completion bash >/etc/bash_completion.d/openshift
