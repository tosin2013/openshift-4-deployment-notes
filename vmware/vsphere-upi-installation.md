# vSphere User Provisioned installation Steps

**Recommend resource requirements**  


Machine  | Operating System  | vCPU  | RAM  |  Storage |  
--|---|---|---|--|  
Bootstrap  | RHCOS  | 4  | 16 GB  | 120 GB|    
Control plane  |  RHCOS | 4  | 16 GB  | 120 GB|    
Compute  |  RHCOS | 4  | 16 GB  |  120 GB|    
Bastion Host (Helper Node)  |  RHEL 7.x  | 4  | 16 GB | 120 GB |   

**For general deployments**  
1. Review Requirements
   1. [Machine requirements for a cluster with user-provisioned infrastructure](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere.html)
2. Configure DNS.
   1. Example [Bind Setup](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/dns-server-configuration)
4. Configure HAProxy. Provision the required load balancers.
   1. Example [HAProxy Configuration](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/haproxy-configuration)
5. Configure webserver
   1. Example [WebServer Configuration](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/webserver-configuration)
6. Configure PXE servers
   1. Example [PXE Configuration](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/pxe-configuration)
7. Configure installer
   1. see [script](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/configure-installers)
8. Configure ignition files
   1. see [README.md](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/configure-ignitionfiles)
9. Configure Machines for OpenShift
  1. [Creating Red Hat Enterprise Linux CoreOS (RHCOS) machines in vSphere](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere.html#installation-vsphere-machines_installing-vsphere)
10.  Startup Machines
11. View run OpenShift installer
   1. Reference [Run OpenShift installer](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/run-ocp-installer)

**For Static IP deployments**  
[OpenShift 4.2 vSphere Install with Static IPs using coreos ISO](https://blog.openshift.com/openshift-4-2-vsphere-install-with-static-ips/)  
[coreos-iso-maker V2.1](https://github.com/chuckersjp/coreos-iso-maker)  
[OpenShift 4.2 vSphere Install with Static IPs using OVA](https://github.com/spagno/ocp4-utils)  

**Links:**  
* [Installing a cluster on vSphere](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere.html)
* [Installing a cluster on vSphere with network customizations](https://docs.openshift.com/container-platform/4.5/installing/installing_vsphere/installing-vsphere-network-customizations.html)
