# BILLI/Agent-based Installer early access

## Required Files
```
export SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export PULL_SECRET_PATH="$HOME/ocp-pull-secret"
```

## Configure Rhel 8.5 system 
```
sudo su - admin
curl -OL https://gist.githubusercontent.com/tosin2013/ae925297c1a257a1b9ac8157bcc81f31/raw/71a798d427a016bbddcc374f40e9a4e6fd2d3f25/configure-rhel8.x.sh
chmod +x configure-rhel8.x.sh
./configure-rhel8.x.sh
sudo dnf install libvirt -y
```

**Download Qubinode Installer**
```
cd $HOME
wget https://github.com/tosin2013/qubinode-installer/archive/refs/heads/cleanup.zip
unzip cleanup.zip
rm cleanup.zip
mv qubinode-installer-cleanup qubinode-installer
cd ~/qubinode-installer
```
**copy rhel-8.5-update-2-x86_64-kvm.qcow2 to qubinode-installer directory**

**Configure Qubinode box**
```
./qubinode-installer -m setup
./qubinode-installer -m rhsm
./qubinode-installer -m ansible
./qubinode-installer -m host
./qubinode-installer -p kcli
./qubinode-installer -p gozones
```

**install latest openshift packages**
```
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
chmod +x configure-openshift-packages.sh
./configure-openshift-packages.sh -i
sudo rm -rf /usr/bin/openshift-install
```

**install golang**
```
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile 
```

**Build openshift-installer**
```
$ git clone https://github.com/openshift/installer
$ cd installer/
$ git checkout agent-installer
$ hack/build.sh
```

**install nmstatgectl**
```
sudo dnf install /usr/bin/nmstatectl -y
```
**create Cluster manifest directory**
```
mkdir cluster-manifests
```

**1. Create agent-cluster-install.yaml**
```
cat << EOF > ./cluster-manifests/agent-cluster-install.yaml
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: ocp4
  namespace: ocp4-cluster
spec:
  apiVIP: 192.168.150.253
  ingressVIP: 192.168.150.252
  clusterDeploymentRef:
    name: ocp4
  imageSetRef:
    name: openshift-v4.10.0
  networking:
    clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
    serviceNetwork:
    - 172.30.0.0/16
  provisionRequirements:
    controlPlaneAgents: 3
    workerAgents: 0 
  sshPublicKey: '$(cat ${SSH_PUB_KEY_PATH})'
EOF
```

**2. Create agent-cluster-install.yaml**
```
cat << EOF > ./cluster-manifests/cluster-deployment.yaml
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ocp4
  namespace: ocp4-cluster
spec:
  baseDomain: lab.qubinode.io
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: ocp4-agent-cluster-install
    version: v1beta1
  clusterName: ocp4
  controlPlaneConfig:
    servingCertificates: {}
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          bla: aaa
  pullSecretRef:
    name: pull-secret
EOF
```

**3. Create cluster-image-set.yaml**
```
cat << EOF > ./cluster-manifests/cluster-image-set.yaml
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: ocp-release-4.11
spec:
  releaseImage: registry.ci.openshift.org/ocp/release:4.11.0-0.nightly-2022-06-06-025509
EOF
```

**4. Create cluster-image-set.yaml**
```
cat << EOF > ./cluster-manifests/infraenv.yaml 
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4
  namespace: ocp4-cluster
spec:
  clusterRef:
    name: ocp4  
    namespace: ocp4-cluster
  pullSecretRef:
    name: pull-secret
  sshAuthorizedKey: '$(cat ${SSH_PUB_KEY_PATH})'
  nmStateConfigLabelSelector:
    matchLabels:
      ocp4-nmstate-label-name: ocp4-nmstate-label-value
EOF
```

**5. Create nmstateconfig.yaml**
```
cat << EOF > ./cluster-manifests/nmstateconfig.yaml
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: mynmstateconfig01
  namespace: openshift-machine-api
  labels:
    ocp4-nmstate-label-name: ocp4-nmstate-label-value
spec:
  config:
    interfaces:
      - name: enp2s0
        type: ethernet
        state: up
        mac-address: 52:54:00:e7:05:72
        ipv4:
          enabled: true
          address:
            - ip: 192.168.150.116
              prefix-length: 24
          dhcp: false
    dns-resolver:
      config:
        server:
          - 192.168.150.1
    routes:
      config:
        - destination: 0.0.0.0/0
          next-hop-address: 192.168.150.1
          next-hop-interface: enp2s0
          table-id: 254
  interfaces:
    - name: "enp2s0"
      macAddress: 52:54:00:e7:05:72
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: mynmstateconfig02
  namespace: openshift-machine-api
  labels:
    ocp4-nmstate-label-name: ocp4-nmstate-label-value
spec:
  config:
    interfaces:
      - name: enp2s0
        type: ethernet
        state: up
        mac-address: 52:54:00:95:fd:f3
        ipv4:
          enabled: true
          address:
            - ip: 192.168.150.117
              prefix-length: 24
          dhcp: false
    dns-resolver:
      config:
        server:
          - 192.168.150.1
    routes:
      config:
        - destination: 0.0.0.0/0
          next-hop-address: 192.168.150.1
          next-hop-interface: enp2s0
          table-id: 254
  interfaces:
    - name: "enp2s0"
      macAddress: 52:54:00:95:fd:f3
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: mynmstateconfig03
  namespace: openshift-machine-api
  labels:
    ocp4-nmstate-label-name: ocp4-nmstate-label-value
spec:
  config:
    interfaces:
      - name: enp2s0
        type: ethernet
        state: up
        mac-address: 52:54:00:e8:b9:18
        ipv4:
          enabled: true
          address:
            - ip: 192.168.150.118
              prefix-length: 24
          dhcp: false
    dns-resolver:
      config:
        server:
          - 192.168.150.1
    routes:
      config:
        - destination: 0.0.0.0/0
          next-hop-address: 192.168.150.1
          next-hop-interface: enp2s0
          table-id: 254
  interfaces:
    - name: "enp2s0"
      macAddress: 52:54:00:e8:b9:18
EOF
```

**6. Get pull secret**
```
cat << EOF > ./cluster-manifests/pull-secret.yaml 
apiVersion: v1
kind: Secret
type: kubernetes.io/dockerconfigjson
metadata:
  name: pull-secret
  namespace: ocp4-cluster
stringData:
  .dockerconfigjson: '$(cat ${PULL_SECRET_PATH})'
EOF
```

**Generate agent.iso**
```
cp -avi cluster-manifests/ ~/cluster-mainfests
ls -l ./cluster-manifests/
bin/openshift-install agent create image 
```

### Optional steps
**Copy agent iso**
```
 sudo cp agent.iso /var/lib/libvirt/images/
```

**test on libvirt vm**
> edit baremetal-test-script.sh as needed
```
bash -x baremetal-test-script.sh
```

**Load the OpenShift with the Assisted Installer UI**
> use the ip address of the first node 
![20220613113231](https://i.imgur.com/lwaV3Mr.png)

> wait for the other nodes to populate 


**Get deployment status**
> we are using the ip for the ocp4-master1 in script
```
curl --silent http://192.168.150.116:8090//api/assisted-install/v2/clusters | jq .
```

# Links:
https://schmaustech.blogspot.com/2022/05/install-openshift-with-agent-installer.html
