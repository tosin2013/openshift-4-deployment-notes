# Configure OpenShift Virtualization networking

## 1. Install the Kubernetes NMState Operator
* https://docs.openshift.com/container-platform/4.10/networking/k8s_nmstate/k8s-nmstate-about-the-k8s-nmstate-operator.html



## 2. Confiure the node

**labels nodes for testing**
```
oc label node ocp01 nodename=ocp01
oc label node ocp02 nodename=ocp02
oc label node ocp03 nodename=ocp03
```

Bridge referance  
-----------
> definitions for network interfaces 
 -> https://nmstate.io/
* [Attaching a virtual machine to a Linux bridge network](https://docs.openshift.com/container-platform/4.10/virt/virtual_machines/vm_networking/virt-attaching-vm-multiple-networks.html)

DHCP Example
------------
```bash
#!/bin/bash
NODENAME=ocp03
PORTNAME=enp9s0
cat <<EOF > ${NODENAME}-nncp.yaml
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: ${NODENAME}-bridge-policy 
spec:
  nodeSelector: 
    nodename: "${NODENAME}"
  desiredState:
    interfaces:
      - name: br1
      # br1 is the name of the first available bridge interface
        description: Linux bridge with ${PORTNAME} as a port 
        type: linux-bridge
        state: up
        ipv4:
          dhcp: true
          enabled: true
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: ${PORTNAME}
            # ${PORTNAME} is the name of the physical NIC on your node
EOF
oc create -f ${NODENAME}-nncp.yaml
```

Static IP Example
-----------------
```bash
#!/bin/bash
NODENAME=ocp03
PORTNAME=enp9s0
cat <<EOF > ${NODENAME}-nncp.yaml
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: ${NODENAME}-bridge-policy 
spec:
  nodeSelector: 
    nodename: "${NODENAME}"
  desiredState:
    interfaces:
      - name: br1
      # br1 is the name of the first available bridge interface
        description: Linux bridge with ${PORTNAME} as a port 
        type: linux-bridge
        state: up
        ipv4:
          address:
            - ip: 192.168.200.10
              prefix-length: 24
          dhcp: false
          enabled: true
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: ${PORTNAME}
            # ${PORTNAME} is the name of the physical NIC on your node
EOF
oc create -f ${NODENAME}-nncp.yaml
```

## Check bridge status of each worker
```
$ oc get nncp
$ oc describe nncp ocp03-bridge-policy
```
![](https://i.imgur.com/Hyj5jet.png)

You can use the cli to configure the bridge policy 
> example router config https://gist.github.com/tosin2013/d47b27bb88b2ac0944fe15f6946bfcc5
```
cat >vlan202.yaml<<EOF
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan202
  namespace: default
spec:
  config: >-
    {"name":"vlan202","type":"cnv-bridge","cniVersion":"0.3.1","bridge":"br1","vlan":202,"macspoofchk":true,"ipam":{}}
EOF
oc create -f vlan202.yaml
```
> In the OpenShift Console click on Network->NetworkAttachmentDefinitions
Click on ![](https://i.imgur.com/6jmwb3h.png)

![](https://i.imgur.com/hKbg7Vk.png)

## Configure VM interface 
> Click on Virtualization->VirtiualMachines click on your VM -> click on Network Interfaces
Click on ![](https://i.imgur.com/FNdZfMD.png)
> You can shutdown the vm before making these changes if you do not you will have to restart the VM.
![](https://i.imgur.com/ZcKFbvb.png)


Links:
https://blog.cudanet.org/setting-up-kubevirt/
