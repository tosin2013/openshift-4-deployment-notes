# Assisted Installer Scripts

## Prerequisites

The following binaries need to be included in the system $PATH:

- curl
- jq
- python3
- j2cli
```
pip3 install j2cli
```

## Assisted Installer Steps for Bare Metal machines with Static IPs

1. Get offline token and save it to `~/rh-api-offline-token`
> [Red Hat API Tokens](https://access.redhat.com/management/api)

```bash
vim ~/rh-api-offline-token
```

2. Get OpenShift Pull Secret and save it to `~/ocp-pull-secret`
> [Install OpenShift on Bare Metal](https://console.redhat.com/openshift/install/metal/installer-provisioned)

```bash
vim ~/ocp-pull-secret
```

3. Ensure there is an SSH Public Key at `~/.ssh/id_rsa.pub`

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

4. Copy the cluster variables example file and modify as needed
> Single NIC Deployments
```bash
cp example.cluster-vars.sh cluster-vars.sh
vim cluster-vars.sh
```
> Multi Nic Deployments
```bash
cp example-mutli-network.cluster-vars.sh cluster-vars.sh
vim cluster-vars.sh
```

5. Run the bootstrap script to create the cluster, configure it, and download the ISO
> the bootstrap-create.sh script may also be used. 
```bash
./bootstrap.sh
```

Sample expected output:

```
[kemo@raza assisted-installer]$ ./bootstrap.sh 

===== Running preflight...

===== Generating asset directory...
===== Checking for needed programs...
curl                                                                     PASSED!
jq                                                                       PASSED!
python3                                                                  PASSED!
===== Authenticating to the Red Hat API...
  Using Token: eyJhbGciOiJSUzI...

===== Querying the Assisted Installer Service for supported versions...
  Found Cluster Release 4.9.4 from target version 4.9

===== Preflight passed...

===== Cluster ai-poc.lab.local not found, creating now...

===== Creating a new cluster...
  CLUSTER_ID: dc3cfcc3-6a11-4fb2-a94f-e4fe8cac617f

===== Generating NMState Configuration files...
  Working with 3 nodes...
  Creating NMState config for ocp01...
  Creating NMState config for ocp02...
  Creating NMState config for ocp03...

===== Setting password authentication for core user...

===== Configuring Discovery ISO...
  Working with 3 nodes...
  Generating ISO Config for ocp01...
  Generating ISO Config for ocp02...
  Generating ISO Config for ocp03...

===== Patching Discovery ISO...

===== Waiting 15s for ISO to build...


===== Downloading Discovery ISO locally to ./.generated/ai-poc.lab.local/ai-liveiso-dc3cfcc3-6a11-4fb2-a94f-e4fe8cac617f.iso ...

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  987M  100  987M    0     0  58.5M      0  0:00:16  0:00:16 --:--:-- 61.6M
```

6. Boot each machine with downloaded ISO

7. Run the `./bootstrap-install.sh` to start deployment to automate the tasks below. 

## Running bootstrap install manually  
> The bootstrap install script calls the scripts below in order. If you would like to walk thru the script call the scripts below. 
* `source cluster-vars.sh && source authenticate-to-api.sh` - sources variables to run scripts below.
* `steps/check-nodes-ready.sh` - Checks to see if all the nodes have reported in
* `steps/set-node-hostnames-and-roles.sh` - Set node hostnames and roles
* `steps/set-networking.sh` - configures network and other settings TBH
* `steps/check-cluster-ready-to-install.sh` - Check to see if the cluster is ready to install
* `steps/start-install.sh` -  Starts the Installation

## Bootstrap Execution Overview

- Run Preflight tasks - ensure files and variables are set, create asset generation directory
- Authenticate to the Assisted Installer Service
- Query the Assisted Installer Service for the supported OCP Release Version
- Create a Cluster in the AI Svc if it does not already exist
- Produce NMState configuration file
- [Optional] Set core user password
- Configure the Discovery ISO
- Download the Discovery ISO

Generated assets can be found in `./.generated/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}/`

## Add worker nodes to deployment
* Run the `add-nodes-bootstrap.sh` script
* After node reboots run the `./hack/auto-approve-certs.sh` script

## Destroy Cluster

A simple script exists to delete a created cluster from the Assisted Installer Service and from the local file system:

```bash
## Requires a set cluster-vars.sh, looks for CLUSTER_ID in the `./.generated/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}/` directory
./destroy.sh
```

## Day 2 - Adding Additional Application Nodes

You can generate the Discovery ISO for a scaling action against a previously deployed cluster.

To do so, modify your `cluster-vars.sh` file to add the additional nodes, eg:

```bash
# ...
NODE6_CFG='{"name": "ocp06", "role": "application-node", "mac_address": "52:54:00:00:00:06", "ipv4": {"address": "192.168.42.66", "gateway": "192.168.42.1", "prefix": "24", "iface": "enp1s0"}}'
NODE7_CFG='{"name": "ocp07", "role": "application-node", "mac_address": "52:54:00:00:00:07", "ipv4": {"address": "192.168.42.67", "gateway": "192.168.42.1", "prefix": "24", "iface": "enp1s0"}}'

## Add Nodes to the JSON array
export NODE_CFGS='{ "nodes": [ '${NODE1_CFG}', '${NODE2_CFG}', '${NODE3_CFG}', '${NODE4_CFG}', '${NODE5_CFG}', '${NODE6_CFG}', '${NODE7_CFG}' ] }'
# ...
```

Then run the bootstrap-scale-up script:

```bash
./bootstrap-scale-up.sh
```

You'll find a new Discovery ISO downloaded in the generated assets folder.

> ***Note:*** You won't see the additional hosts cluster defined in the Web UI - additional node actions are performed via the API and oc CLI

Once the additional hosts have booted and reported in, you can run the bootstrap-scale-up script again and it should kick off the installation process.

```bash
./bootstrap-scale-up.sh
```

Having already `oc login`'d to the original cluster, wait for the host to report in as a node's CertificateSigningRequest and approve it:
> See `./hack/auto-approve-certs.sh`

```bash
oc get csr|grep Pending

# Approve all CSR
for csr in $(oc -n openshift-machine-api get csr | awk '/Pending/ {print $1}'); do oc adm certificate approve $csr;done
```

## Links

* [Assisted Installer API Swagger Documentation](https://generator.swagger.io/?url=https://raw.githubusercontent.com/openshift/assisted-service/master/swagger.yaml)
* https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive
* [Assisted Installer on premise deep dive](https://github.com/latouchek/assisted-installer-deepdive)
* https://github.com/kenmoini/ocp4-ai-svc-libvirt
* https://cloudcult.dev/creating-openshift-clusters-with-the-assisted-service-api/
* https://kenmoini.com/post/2022/01/disconnected-openshift-assisted-installer-service/

## Branch Testing for Developers
> Review [Hack-y](hack/README.md) scripts before start testing

```bash
## Clone & Checkout
git clone https://github.com/tosin2013/openshift-4-deployment-notes.git
cd openshift-4-deployment-notes

git checkout kemo-patch-2
cd assisted-installer/

## Copy/edit vars
cp example.cluster-vars.sh cluster-vars.sh
vim cluster-vars.sh

## Start a full libvirt install
## - Create the OpenShift Cluster in the AI Service
## - [Optional Hack] Create VMs locally with Libvirt
## - Configure and Start the OpenSHift Install via the AI Service
## - [Optional Hack] Watch virsh and restart VMs when needed
## - Post-Install Cluster Configuration & Output

./bootstrap.sh \
 && ./hack/create-kvm-vms.sh \
 && ./bootstrap-install.sh \
 && ./hack/watch-and-reboot-kvm-vms.sh #test for node addition \
 && ./bootstrap-post-install.sh


 ## to add aditional test vm 
./add-nodes-bootstrap.sh
./hack/create-kvm-vms.sh 

 ## To destory test vms
 ./hack/delete-kvm-vms.sh 
 ./destroy.sh
```


