#  Packer configuration files for building Red Hat CoreOS Images for VMware ESXi 6.7 platform To deploy OpenShift 4.x - WIP 

### Prerequisite to running the build process:

- Clone this repository
```
https://github.com/tosin2013/openshift-4-deployment-notes.git
```

- Configure the `.variables` file _[Note: Ensure to add this file to your .gitignore or keep it outside your repository to avoid accidentally uploading passwords to your repository]_

``` json
{
    "vcenter_server":"YOUR VCENTRE IP ADDRESS",
    "username":"administrator@vsphere.local",
    "password":"VCENTRE PASSWORD",
    "datastore":"datastore1",
    "folder": "ocp4",
    "host":"ESXi IP ADDRESS",
    "cluster": "",
    "network": "VM Network",
    "resource_pool": "",
    "ssh_username": "grazzer",
    "ssh_password": "grazzer"
}
```

-  Register first, then attach a subscription in the Customer Portal
```
subscription-manager register
```
-  Attach a specific subscription through the Customer Portal
```
subscription-manager refresh
```
-  Attach a subscription from any available that match the system
```
subscription-manager attach --auto
```

-  list pool ids
```
subscription-manager list --available
```

-  Install Ansible 
```
subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
yum install -y ansible
```
-  enable extras repo
``` 
subscription-manager repos --enable rhel-7-server-extras-rpms
```
-  install git
```
yum install -y git 
yum install -y patch 
```

- Configue helper node folllowing the instructions in git repo
```
git clone https://github.com/christianh814/ocp4-upi-helpernode.git
cd ocp4-upi-helpernode
```
- after helper node deployment disable dhcp
```
systemctl disable dhcpd
```
- Generate vshpere ignition configs
```
https://github.com/tosin2013/ocp4-vsphere-upi-automation/
```

-  download packer 
```
curl -OL https://releases.hashicorp.com/packer/1.3.5/packer_1.3.5_linux_amd64.zip
```
-  install packer
```
unzip packer_1.3.5_linux_amd64.zip
mv packer /usr/local/bin/
```

-  download packer builder vsphere  
```
https://github.com/jetbrains-infra/packer-builder-vsphere/releases/download/v2.3/packer-builder-vsphere-iso.linux
```


-  Link the packer-builder-vsphere-iso to the folders below 
```
ln -s 
```

-  packer commands for iso deployments
```
packer build -var-file=../.variables bootstrap-iso.json
```

```
packer build -var-file=.variables masternode/master-0-iso.json
packer build -var-file=.variables masternode/master-1-iso.json
packer build -var-file=.variables masternode/master-2-iso.json
```

```
packer build -var-file=.variables workernode/worker-0-iso.json
packer build -var-file=.variables workernode/worker-1-iso.json
packer build -var-file=.variables workernode/worker-2-iso.json
```



### Known errors
Packer version 1.3.5 was used as the brew install of Packer at the time of writing defaulted to version 1.4.1 and this caused [false ISO download issues](https://github.com/hashicorp/packer/issues/7622) when working with VMware/vCenter 6.7.

This is the error I keep getting when using Packer 1.4.0 - 1.4.2 :

``` text
==> vsphere-iso: Retrieving ISO
    vsphere-iso: Error downloading: open : no such file or directory
==> vsphere-iso: ISO download failed.
Build 'vsphere-iso' errored: ISO download failed.

==> Some builds didn't complete successfully and had errors:
--> vsphere-iso: ISO download failed.

==> Builds finished but no artifacts were created.
```

