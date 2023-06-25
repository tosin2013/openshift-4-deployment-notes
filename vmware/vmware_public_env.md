# VMware Cloud Public Cloud Open Environment

## Overview
This document describes the steps to deploy an OpenShift 4.x cluster on VMware Cloud Public Cloud Open Environment.

## Prerequisites
* VMware Cloud Public Cloud Open Environment account
  
## Steps
* Ssh to the bastion host
* Curl the rhpds-quickstart.sh and run it
```
./rhpds-quickstart.sh  <vCenter URL> <Base Domain> <API VIP> <Ingress VIP> <Subnet CIDR>
```

## Links
* https://access.redhat.com/solutions/6677901
* https://docs.openshift.com/container-platform/4.11/installing/installing_vsphere/installing-vsphere-installer-provisioned.html