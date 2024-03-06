#!/bin/bash
# https://cloud.redhat.com/blog/meet-the-new-agent-based-openshift-installer-1
# MUST ADD disk.EnableUUID to TRUEsee below
# https://sort.veritas.com/public/documents/sfha/6.2/vmwareesx/productguides/html/sfhas_virtualization/ch10s05s01.htm

export SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export PULL_SECRET_PATH="$HOME/pull_secret.json"
export KVM_DEPLOY="FALSE"
export INSTALL_FILE="install-config.yaml"
export EXTRA_FILE="extra-config.yaml"
export OCTECT="192.168.100"
export MAC_ADDRESS="00:50:56:a2:c9:22"
export VSPHERE_DATASTORE="Datastore"
export DATASTORE_FOLDER="ISOs"

# install nmstate cli 
# sudo yum install nmstate -y 
if [ ! -f $PULL_SECRET_PATH ];
then 
    echo "Please download the pull secret from https://cloud.redhat.com/openshift/install/pull-secret"
    echo "and save it to $PULL_SECRET_PATH"
    exit 1
fi

if [ ! -f $SSH_PUB_KEY_PATH ];
then 
    echo "Please generate a ssh key and save it to $SSH_PUB_KEY_PATH"
    exit 1
fi

# Define target directory for readline
read -p "Enter the target directory: " TARGET_DIR
# Enter target DNS SERVER 
read -p "Enter the target DNS server: " TARGET_DNS_SERVER

if [ ! -d $HOME/${TARGET_DIR} ];
then 
    mkdir -p $HOME/${TARGET_DIR}
fi

cd $HOME/${TARGET_DIR}
# openshift-install agent create  agent-config-template --dir .

cat > agent-config.yaml << EOF
apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: sno-cluster
rendezvousIP: ${OCTECT}.80
hosts:
  - hostname: sno-0
    interfaces:
      - name: ens192
        macAddress: ${MAC_ADDRESS}
    rootDeviceHints:
      deviceName: /dev/sda
    networkConfig:
      interfaces:
        - name: ens192
          type: ethernet
          state: up
          mac-address: ${MAC_ADDRESS}
          ipv4:
            enabled: true
            address:
              - ip: ${OCTECT}.80
                prefix-length: 24
            dhcp: false
      dns-resolver:
        config:
          server:
            - ${TARGET_DNS_SERVER}
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: ${OCTECT}.1
            next-hop-interface: ens192
            table-id: 254
EOF


# Save the updated agent configuration template
cat agent-config.yaml

# Print a message to the user
echo "The agent configuration template has been updated."
sleep 5s

cat << EOF > install-config.yaml
apiVersion: v1
baseDomain: example.com
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: 1
metadata:
  name: sno-cluster 
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: ${OCTECT}.0/24
  networkType: OVNKubernetes 
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '$(cat ${PULL_SECRET_PATH})' 
sshKey: '$(cat ${SSH_PUB_KEY_PATH})' 
EOF

if [[ -f $HOME/$EXTRA_FILE ]]; then
    if [[ -f $INSTALL_FILE ]]; then
        cat $HOME/$EXTRA_FILE >> $INSTALL_FILE
        echo "Content from $HOME/$EXTRA_FILE appended to $INSTALL_FILE."
    else
        echo "File $INSTALL_FILE does not exist. Content not appended."
    fi
else
    echo "File $HOME/$EXTRA_FILE does not exist. Content not appended."
fi

cat install-config.yaml
sleep 5s
openshift-install agent create cluster-manifests --dir "$HOME/${TARGET_DIR}" || exit $?
openshift-install --dir "$HOME/${TARGET_DIR}" agent create image  || exit $?


# export GOVC_URL=https://${vcenter_fqdn}/sdk
# export GOVC_USERNAME=administrator@vsphere.local
# export GOVC_PASSWORD="vsphere-password"
if [ -z "$GOVC_URL" ];
then 
    echo "Please set the GOVC_URL environment variable"
    exit 1
fi
govc datastore.upload -ds ${VSPHERE_DATASTORE}  $HOME/${TARGET_DIR}/agent.x86_64.iso ${DATASTORE_FOLDER}/agent.x86_64.iso 

## To delete agent.x86_64.iso
# govc datastore.rm -ds=${VSPHERE_DATASTORE} ${DATASTORE_FOLDER}/agent.x86_64.iso

echo "Run the following commands check cluster status"
echo "export KUBECONFIG=$HOME/${TARGET_DIR}/auth/kubeconfig"
echo cd $HOME/${TARGET_DIR}
echo openshift-install agent wait-for install-complete --dir .
