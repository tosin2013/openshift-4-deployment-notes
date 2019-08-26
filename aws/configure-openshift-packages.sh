#!/bin/bash 
URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/" 
OC_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/  | grep -o openshift-install-linux-4.1.[0-9][0-9].tar.gz | head -1)
wget ${URL}${OC_INSTALLER}
tar zxvf ${OC_INSTALLER} -C /usr/bin 
rm -f ${OC_INSTALLER}
chmod +x /usr/bin/openshift-install 
openshift-install version

OC_CLI_CLIENT=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/  | grep -o 	openshift-client-linux-4.1.[0-9][0-9].tar.gz | head -1)
wget ${URL}${OC_CLI_CLIENT}
tar zxvf ${OC_CLI_CLIENT} -C /usr/bin
rm -f ${OC_CLI_CLIENT}
chmod +x /usr/bin/oc 
oc version

oc completion bash >/etc/bash_completion.d/openshift 

