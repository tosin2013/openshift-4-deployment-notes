#!/bin/bash
VERSION="4.2."
DEV_PREVIEW="ocp-dev-preview"
URL="https://mirror.openshift.com/pub/openshift-v4/clients/${DEV_PREVIEW}/latest/"
#OC_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/${DEV_PREVIEW}/latest/  | grep -o openshift-install-linux-${VERSION}.tar.gz | head -1)
OC_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/${DEV_PREVIEW}/latest/ | grep -oE openshift-install-linux-${VERSION}"(.*)".tar.gz | cut -d'"' -f2  | tr -d '>')

wget ${URL}${OC_INSTALLER}
sudo tar zxvf ${OC_INSTALLER} -C /usr/bin
sudo rm -f ${OC_INSTALLER}
sudo chmod +x /usr/bin/openshift-install
openshift-install version

OC_CLI_CLIENT=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/${DEV_PREVIEW}/latest/  | grep -oE 	openshift-client-linux-${VERSION}"(.*)".tar.gz | cut -d'"' -f2  | tr -d '>')
wget ${URL}${OC_CLI_CLIENT}
sudo tar zxvf ${OC_CLI_CLIENT} -C /usr/bin
sudo rm -f ${OC_CLI_CLIENT}
sudo chmod +x /usr/bin/oc
oc version

oc completion bash >/etc/bash_completion.d/openshift
