#!/bin/bash
if [ -z "$GUID" ]; then
  echo "GUID is not set"
  exit 1
fi

if [ -z "$1" ]; then
  echo "VCENTER_PASSWORD is not set"
  exit 1
fi

if [ -z "$2" ]; then
  echo "API_VIP is not set"
  exit 1
fi

if [ -z "$3" ]; then
  echo "APPS_VIP is not set"
  exit 1
fi

if [ -z "$PULL_SECRET_PATH" ]; then
  echo "PULL_SECRET_PATH is not set"
  exit 1
fi

if [ -z "$SSH_PUB_KEY_PATH" ]; then
  echo "SSH_PUB_KEY_PATH is not set"
  exit 1
fi

export VCENTER_PASSWORD=$1
export API_VIP=$2
export APPS_VIP=$3

### DO NOT NEED TO CHANGE ANYTHING BELOW THIS LINE ###
export DOMAIN=dynamic.opentlc.com
export CLUSTER_NAME=$GUID
export DATA_CENTER="SDDC-Datacenter"
export VMWARE_CLUSTER="Cluster-1"
export DATA_STORE="WorkloadDatastore"
export NETWORK="segment-sandbox-${GUID}"
export FOLDER="Workloads/sandbox-${GUID}"
export VCENTER_URL="portal.vc.opentlc.com"
export VCENTER_USER="sandbox-${GUID}@vc.opentlc.com"

mkdir -p cluster_$GUID
cat >cluster_$GUID/install-config.yaml<<EOF
apiVersion: v1
baseDomain: ${DOMAIN}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
  platform:
    vsphere:
      cpus:  4
      coresPerSocket:  2
      memoryMB:  16384
      osDisk:
        diskSizeGB: 120
compute:
- hyperthreading: Enabled
  name: 'worker'
  replicas: 3
  platform:
    vsphere:
      cpus:  4
      coresPerSocket:  2
      memoryMB:  16384
      osDisk:
        diskSizeGB: 120
metadata:
  name: ${CLUSTER_NAME} 
platform:
  vsphere: 
    apiVIPs:
      - ${API_VIP}
    failureDomains: 
    - name: default
      region: region1
      server: ${VCENTER_URL}
      topology:
        computeCluster: "/${DATA_CENTER}/host/${VMWARE_CLUSTER}"
        datacenter: ${DATA_CENTER}
        datastore: "/${DATA_CENTER}/datastore/${DATA_STORE}"
        networks:
        - ${NETWORK}
        folder: "/${DATA_CENTER}/vm/${FOLDER}"
      zone: zone1
    ingressVIPs:
    - ${APPS_VIP}
    vcenters:
    - datacenters:
      - ${DATA_CENTER}
      password: ${VCENTER_PASSWORD}
      port: 443
      server: ${VCENTER_URL}
      user: ${VCENTER_USER}
    diskType: thin 
fips: false
pullSecret: '$(cat ${PULL_SECRET_PATH})' 
sshKey: '$(cat ${SSH_PUB_KEY_PATH})' 
EOF