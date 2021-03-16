# vSphere User Provisioned w/static ip installation steps
These steps for compatiable witht an OpenShift 4.6 deployment.

**Recommend resource requirements**  


Machine  | Operating System  | vCPU  | RAM  |  Storage |  
--|---|---|---|--|  
Bootstrap  | RHCOS  | 4  | 16 GB  | 120 GB|    
Control plane  |  RHCOS | 4  | 16 GB  | 120 GB|    
Compute  |  RHCOS | 4  | 16 GB  |  120 GB|    
Bastion Host (Helper Node)  |  RHEL 7.x  | 4  | 16 GB | 120 GB |   

## Bastion Prerequisites 
**Install required software**
 *  Configure installer see [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh)
 * Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-rhel-centos-or-fedora) 
 * Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) 
 * Install [govc](https://github.com/vmware/govmomi/releases/tag/v0.23.0)

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

**For general deployments**  
1. Review Requirements
   1. [Machine requirements for a cluster with user-provisioned infrastructure](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html)
2. Configure DNS.
   1. Example [Bind Setup](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/dns-server-configuration)
4. Configure HAProxy. Provision the required load balancers.
   1. Deploy HA Proxy  
      * [HAProxy Configuration Document](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/haproxy-configuration)
      * [haproxy-tcp.cfg](haproxy-configuration/haproxy-tcp.cfg) will be used in this example 
5. Optional: Configure PXE servers
   1. Example [PXE Configuration](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/pxe-configuration)
6. Static Deployment terraform script
   1. [ironicbadger/ocp4](https://github.com/tosin2013/ocp4)
7. Review OpenShift deployment steps after deploying via terraform srcipt
   * [Creating the cluster](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-installing-bare-metal_installing-vsphere)
   * [Logging in to the cluster](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#cli-logging-in-kubeadmin_installing-vsphere)
   * [Approving the CSRs for your machines](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-approve-csrs_installing-vsphere)
   * [Initial Operator configuration](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-operators-config_installing-vsphere)
8. Configure Registry
   * [Image registry storage configuration](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-registry-storage-config_installing-vsphere)
   * [Configuring storage for the image registry in non-production clusters](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-registry-storage-non-production_installing-vsphere)
   * [Configuring block registry storage for VMware vSphere](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-registry-storage-block-recreate-rollout_installing-vsphere)
9. [Completing installation on user-provisioned infrastructure](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-registry-storage-block-recreate-rollout_installing-vsphere)


**Links:**  
* [Installing a cluster on vSphere](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html)
* [Installing a cluster on vSphere with network customizations](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere-network-customizations.html)
* [How to Install OpenShift 4.6 using Terraform on VMware with UPI](https://www.openshift.com/blog/how-to-install-openshift-4.6-on-vmware-with-upi)