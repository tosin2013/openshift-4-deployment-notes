#!/bin/bash
# https://cloud.redhat.com/blog/meet-the-new-agent-based-openshift-installer-1git a
export SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export PULL_SECRET_PATH="$HOME/pull_secret.json"
export KVM_DEPLOY="TRUE"

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
#openshift-install agent create  agent-config-template --dir .

cat > agent-config.yaml << EOF
apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: sno-cluster
rendezvousIP: 192.168.122.80
hosts:
  - hostname: master-0
    interfaces:
      - name: enp2s0
        macAddress: 52:54:00:e7:05:72
    rootDeviceHints:
      deviceName: /dev/vda
    networkConfig:
      interfaces:
        - name: enp2s0
          type: ethernet
          state: up
          mac-address: 52:54:00:e7:05:72
          ipv4:
            enabled: true
            address:
              - ip: 192.168.122.80
                prefix-length: 23
            dhcp: false
      dns-resolver:
        config:
          server:
            - ${TARGET_DNS_SERVER}
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.122.1
            next-hop-interface: enp2s0
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
  - cidr: 192.168.122.0/24
  networkType: OVNKubernetes 
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '$(cat ${PULL_SECRET_PATH})' 
sshKey: '$(cat ${SSH_PUB_KEY_PATH})' 
EOF

cat install-config.yaml
sleep 5s
openshift-install agent create cluster-manifests --dir "$HOME/${TARGET_DIR}" || exit $?
openshift-install --dir "$HOME/${TARGET_DIR}" agent create image  || exit $?

if [ $KVM_DEPLOY == "TRUE" ];
then 
  sudo rm -rf /var/lib/libvirt/images/agent.x86_64.iso
  sudo cp agent.x86_64.iso /var/lib/libvirt/images/
fi 

echo "Run the following commands check cluster status"
echo "export KUBECONFIG=$HOME/${TARGET_DIR}/auth/kubeconfig"
echo cd $HOME/${TARGET_DIR}
echo openshift-install agent wait-for install-complete --dir .