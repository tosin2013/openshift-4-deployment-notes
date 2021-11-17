# Assisted Installer Scripts

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

6. Boot each machine with downloaded ISO


## Bootstrap Execution Overview

- Run Preflight tasks - ensure files and variables are set, create asset generation directory
- Authenticate to the Assisted Installer Service
- Query the Assisted Installer Service for the supported OCP Release Version
- Create a Cluster in the AI Svc if it does not already exist
- Produce NMState configuration file
- Configure the Discovery ISO
- [Optional] Set core user password
- Download the Discovery ISO

Generated assets can be found in `./.generated/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}/`

## Links

* [Assisted Installer API Swagger Documentation](https://generator.swagger.io/?url=https://raw.githubusercontent.com/openshift/assisted-service/master/swagger.yaml)
* https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive
* https://github.com/kenmoini/ocp4-ai-svc-libvirt
* https://cloudcult.dev/creating-openshift-clusters-with-the-assisted-service-api/