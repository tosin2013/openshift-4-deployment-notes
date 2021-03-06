# Configure ignition files
Ignition files are used by the RHCOS to determine hwo to configure each node.

Run the following the machine you plan to install OpenShift from after you have configured the installer.

**Define OpenShift Version**
```
$ export OC_VERSION="4.2.0"
```

**Generate Cluster key**
```
$ ssh-keygen -t rsa -b 4096 -f ~/.ssh/cluster-key -N ''

$ chmod 400 /home/$USER/.ssh/cluster-key.pub
$ cat  /home/$USER/.ssh/cluster-key.pub
```

**Add key to environment so you may ssh into coreos node**
```
eval "$(ssh-agent -s)"
ssh-add  /home/$USER/.ssh/cluster-key.pub
```

**Create Directory for config files**
```
mkdir -p ocp4
cd ocp4
```

**Get pull secert from the url below**
* https://cloud.openshift.com/clusters/install

**Create a reference bare metal  install-config**
```
cat >install-config-base.yaml<<EOF
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 2
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: 'Fill with pull secert'
sshKey: 'Fill with cluster-key.pub key generated key file output'
EOF
```
**Create a reference vSphere install-config**
```
cat >install-config-base.yaml<<EOF
apiVersion: v1
baseDomain: example.com, .ext-example.com
proxy:
  httpProxy: http://<username>:<pswd>@<ip>:<port>
  httpsProxy: http://<username>:<pswd>@<ip>:<port>
  noProxy: example.com
additionalTrustBundle: |
    -----BEGIN CERTIFICATE-----
    <MY_TRUSTED_CA_CERT>
    -----END CERTIFICATE-----
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
  machineCIDR: 192.168.1.0/24
platform:
  vsphere:
    vcenter: your.vcenter.server
    username: username
    password: password
    datacenter: datacenter
    defaultDatastore: datastore
pullSecret: 'Fill with pull secert'
sshKey: 'Fill with cluster-key.pub key generated key file output'
EOF
```

**Copy reference install config to final**
```
cp install-config-base.yaml install-config.yaml
```

**Create install configs**
```
openshift-install create ignition-configs --dir=ocp4
```

**For Bare Metal Installations Follow**  
[Creating the Kubernetes manifest and Ignition config files](https://docs.openshift.com/container-platform/4.2/installing/installing_bare_metal/installing-bare-metal.html#installation-user-infra-generate-k8s-manifest-ignition_installing-bare-metal)  


**For VMWARE Installations Follow**
[Creating Red Hat Enterprise Linux CoreOS (RHCOS) machines in vSphere](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-vsphere-machines_installing-vsphere)

**Copy install bootstrap.ign master.ign and worker.ign to helpernode or webserver**
```
# example directory
$ ls /var/www/html/openshift4/4.2/ignitions/
bootstrap.ign  master.ign  worker.ign
```
