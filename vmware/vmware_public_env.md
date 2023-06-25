# VMware Cloud Public Cloud Open Environment

## Overview
This document describes the steps to deploy an OpenShift 4.x cluster on VMware Cloud Public Cloud Open Environment.

## Prerequisites
* VMware Cloud Public Cloud Open Environment account
  
## Steps
* ssh to the bastion host
* Curl the rhpds-quickstart.sh and run it
```
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/vmware/rhpds-quickstart.sh
chmod +x rhpds-quickstart.sh
./rhpds-quickstart.sh  <vCenter URL> <Base Domain> <API VIP> <Ingress VIP> <Subnet CIDR>
```

## Deploy Infra Nodes w/ODF
**While Infra Nodes are deploy attach hard drive**
![20230625164338](https://i.imgur.com/s1404Os.png)
```
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/vmware/configure-rhdps-vshpere.sh
chmod +x configure-rhdps-vshpere.sh
./configure-rhdps-vshpere.sh
```

## Configure image registry
* [Configuring the Registry for Perisistent Storage](configuring-registry.md)

## Links
* https://access.redhat.com/solutions/6677901
* https://docs.openshift.com/container-platform/4.11/installing/installing_vsphere/installing-vsphere-installer-provisioned.html