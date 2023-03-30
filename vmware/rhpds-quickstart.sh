#!/bin/bash

# Check that all arguments were provided
if [ $# -ne 5 ]; then
    echo "Usage: $0 <vCenter URL> <Base Domain> <API VIP> <Ingress VIP> <Subnet CIDR>"
    exit 1
fi

VCENTER_URL=$1
BASE_DOMAIN=$2
API_VIP=$3
INGRESS_VIP=$4
SUBNET_CIDR=$5

# Check that variables have valid values
if [[ ! $VCENTER_URL =~ ^[a-zA-Z0-9.-]+[.][a-zA-Z]+$ ]]; then
    echo "Error: Invalid vCenter URL"
    exit 1
fi

if [[ ! $BASE_DOMAIN =~ ^[a-zA-Z0-9.-]+[.][a-zA-Z]+$ ]]; then
    echo "Error: Invalid Base Domain"
    exit 1
fi

if [[ ! $API_VIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid API VIP"
    exit 1
fi

if [[ ! $INGRESS_VIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid Ingress VIP"
    exit 1
fi

if [[ ! $SUBNET_CIDR =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    echo "Error: Invalid Subnet CIDR"
    exit 1
fi

# If we made it this far, all checks passed
echo "vCenter URL: $VCENTER_URL"
echo "Base Domain: $BASE_DOMAIN"
echo "API VIP: $API_VIP"
echo "Ingress VIP: $INGRESS_VIP"
echo "Subnet CIDR: $SUBNET_CIDR"

if [ -f /usr/local/bin/oc ]; then
    echo "OpenShift binaries already installed"
    exit 0
else 
    echo "Installing OpenShift binaries"
    curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
    chmod +x configure-openshift-packages.sh
    export VERSION=latest-4.11
    ./configure-openshift-packages.sh -i
fi

if [ -f /usr/local/bin/yq ]; then
    echo "yq already installed"
else
    echo "Installing yq"
    curl -OL https://github.com/mikefarah/yq/releases/download/v4.33.1/yq_linux_amd64.tar.gz
    tar xzvf yq_linux_amd64.tar.gz
    sudo mv yq_linux_amd64 /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
fi


if [ ! -f ~/.ssh/cluster-key ]; then
    echo "Generating SSH key"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/cluster-key -N ''
    chmod 400 ~/.ssh/cluster-key
    cat  ~/.ssh/cluster-key.pub
fi

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key 

if [ ! -f $HOME/download.zip ]; then
    echo "Downloading vCenter certificates"
    curl -OL -k https://$VCENTER_URL/certs/download.zip
    unzip download.zip 
    sudo cp certs/lin/* /etc/pki/ca-trust/source/anchors
    sudo update-ca-trust extract
fi

mkdir cluster_$GUID
echo "Creating install-config.yaml"
echo "VCENTER_URL: ${VCENTER_URL}
BASE_DOMAIN: ${BASE_DOMAIN}
CLUSTER_NAME: $GUID
API_VIP: ${API_VIP}
INGRESS_VIP: ${INGRESS_VIP}
SUBNET_CIDR: ${SUBNET_CIDR}"
openshift-install create install-config --dir=cluster_$GUID

# 4.12 Edits
#yq eval '.platform.vsphere.ingressVIPs[0] = "'${INGRESS_VIP}'"'  cluster_$GUID/install-config.yaml -i
#yq eval '.platform.vsphere.apiVIPs[0] = "'${API_VIP}'"'  cluster_$GUID/install-config.yaml -i
#yq eval '.networking.machineNetwork[0].cidr = "'${SUBNET_CIDR}'"' cluster_$GUID/install-config.yaml -i
#yq eval '.platform.vsphere.folder = "/SDDC-Datacenter/vm/Workloads/sandbox-'$GUID'"' cluster_$GUID/install-config.yaml -i

# 4.11 edits 
yq eval '.networking.machineNetwork[0].cidr = "'${SUBNET_CIDR}'"' cluster_$GUID/install-config.yaml -i
yq eval '.platform.vsphere.folder = "/SDDC-Datacenter/vm/Workloads/sandbox-'$GUID'"' cluster_$GUID/install-config.yaml -i

cat cluster_$GUID/install-config.yaml

openshift-install create cluster --dir=cluster_$GUID --log-level debug


#openshift-install destroy cluster --dir=cluster_$GUID --log-level debug
# rm -rf cluster_$GUID