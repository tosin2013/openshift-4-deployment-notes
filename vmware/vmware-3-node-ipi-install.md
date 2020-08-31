# vSphere 3 node IPI install

## Prerequisites
* DNS Server 
* DHCP Server
* Bation host to run commands 
* unzip
* wget
* curl 

## Default Resource requirements  


Machine  | Operating System  | vCPU  | RAM  |  Storage |  
--|---|---|---|--|  
Bootstrap  | RHCOS  | 4  | 16 GB  | 120 GB|    
3 Master/Compute nodes  |  RHCOS | 4  | 16 GB  | 120 GB|    



## Cluster Resources
A standard OpenShift Container Platform installation creates the following vCenter resources:

* 1 Folder
* 1 Tag category
* 1 Tag
* Virtual machines:
  * 1 template
  * 1 temporary bootstrap node
  * 3  master/compute nodes

## Review vCenter Requirements and permissions 
[Required vCenter account privileges](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#installation-vsphere-installer-infra-requirements_installing-vsphere-installer-provisioned)


## DNS Server Configuration 
* Add the following DNS records to dns server

**Example below is using bind**
```
$ cat /var/named/ocp4.example.lab.db 
$ORIGIN ocp4.example.lab.
$TTL 900
@ IN SOA dns.ocp4.example.lab. root.ocp4.example.lab. (
2020122002 1D 1H 1W 3H
)
@ IN NS dns.ocp4.example.lab.

root IN A 10.90.30.100
dns  IN A 10.90.30.100
api              IN  A   10.90.30.101
api-int          IN  A   10.90.30.101
*.apps           IN  A   10.90.30.102

```

## Bastion Instructions
**Generate cluster-key**
```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cluster-key -N ''
chmod 400 ~/.ssh/cluster-key .pub
cat  ~/.ssh/cluster-key.pub
```

**Start the ssh-agent process as a background task and add key to ssh-agent**
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key 
```


**Install oc cli and openshift-installer**
* You may use the script found below.
  * Configure OpenShift Packages -> [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh)
```
$ ./configure-openshift-packages.sh 
./configure-openshift-packages.sh [OPTION]

 Options:
  -i, --install     Install OpenShift latest binaries
  -d, --delete      Remove oc client and openshift-install
  -h, --help        Display this help and exit

  To install OpenShift pre-release binaries
  ./configure-openshift-packages.sh  --install -v pre-release

```

**Download trusted root CA certificates from the vSphere Web Services SDK**
```
export vcenter_fqdn=my_vcenter_fqdn
curl -OL -k https://$vcenter_fqdn/certs/download.zip
```

**unzip the certs**
```
unzip download.zip 
```

**Copy the certs into the anchors directory**
```
cp certs/lin/* /etc/pki/ca-trust/source/anchors
```

**Update the ca-trust**
```
update-ca-trust extract
```

**make cluster installation directory**
```
mkdir my_ocp4_cluster
```

**create Cluster config**
```
openshift-install create install-config --dir=my_ocp4_cluster
```

**install-config.yaml should be created**
```
$ ls my_ocp4_cluster/
install-config.yaml

```

**Change the worker replica count to 0 in install-config.yaml**
```
$ cat cluster/install-config.yaml 
apiVersion: v1
baseDomain: example.lab
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 0
```


**Optional: Change the master setting  in install-config.yaml for logging**
```
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: 3
  platform:
    vsphere:
      cpus: 4
      coresPerSocket: 2
      memoryMB: 32768
      osDisk:
        diskSizeGB: 200

```

**Deploy Cluster**
```
openshift-install create cluster --dir=my_ocp4_cluster --log-level=info 
```

**Login to cluster**
```
export KUBECONFIG=my_ocp4_cluster/auth/kubeconfig
```

**Test login**
```
$ oc whoami
system:admin
```

**Configure image registry**  
[Configuring registry storage for VMware vSphere](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#registry-configuring-storage-vsphere_installing-vsphere-installer-provisioned)


## Known issues
* openshift-installer destory command has issues on failed deployment.
[OpenShift destory cluster command fails when ran on vSphere 6.7](https://bugzilla.redhat.com/show_bug.cgi?id=1871306)
* 3 Node master/worker deployment does not work with OpenShift logging operator

## Testing 
* Cluster logging on 3 node OpenShift Cluster
  * https://github.com/tosin2013/openshift-4.x-cluster-logger/tree/4.6.x
  * https://docs.openshift.com/container-platform/4.5/logging/cluster-logging-upgrading.html

## Links: 
https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere-installer-provisioned.html


