# Assisted Installer Scripts

## Prerequisites

The following binaries need to be included in the system $PATH:

- curl
- jq
- python3

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

```bash
cp example.cluster-vars.sh cluster-vars.sh
vim cluster-vars.sh
```

5. Run the bootstrap script to create the cluster, configure it, and download the ISO

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

## Destroy Cluster

A simple script exists to delete a created cluster from the Assisted Installer Service and from the local file system:

```bash
## Requires a set cluster-vars.sh, looks for CLUSTER_ID in the `./.generated/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}/` directory
./destroy.sh
```

## Links

* [Assisted Installer API Swagger Documentation](https://generator.swagger.io/?url=https://raw.githubusercontent.com/openshift/assisted-service/master/swagger.yaml)
* https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive
* https://github.com/kenmoini/ocp4-ai-svc-libvirt
* https://cloudcult.dev/creating-openshift-clusters-with-the-assisted-service-api/

## Branch Testing Cheat Code

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

./bootstrap-create.sh \
 && ./hack/create-kvm-vms.sh \
 && ./bootstrap-install.sh \
 && ./hack/watch-and-reboot-kvm-vms.sh \
 && ./bootstrap-post-install.sh
```