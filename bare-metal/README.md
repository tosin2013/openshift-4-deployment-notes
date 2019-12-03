# Bare Metal Steps

**For general deployments**  
1. Review Requirements
   1. [Machine requirements for a cluster with user-provisioned infrastructure](https://docs.openshift.com/container-platform/4.2/installing/installing_bare_metal/installing-bare-metal.html?extIdCarryOver=true&sc_cid=701f2000001Css5AAC#installation-requirements-user-infra_installing-bare-metal)
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
9.  Startup Machines
10. View run OpenShift installer
  1. Reference [Run OpenShift installer](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/run-ocp-installer)

**For Static IP deployments**  
Use [filetranspiler](https://github.com/ashcrow/filetranspiler) this will generate a igition json file with addtions from a fake root.

Example is from bootstrap node.
```
mkdir -p bootstrap/etc/sysconfig/network-scripts/
```

Create network inside this fakeroot. nYour interface may be different.
```
cat < bootstrap/etc/sysconfig/network-scripts/ifcfg-enp1s0
DEVICE=enp1s0
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.168.7.20
NETMASK=255.255.255.0
GATEWAY=192.168.7.1
DNS1=192.168.7.77
DNS2=8.8.8.8
DOMAIN=ocp4.example.com
PREFIX=24
DEFROUTE=yes
IPV6INIT=no
EOF
```

Using filetranspiler, create a new ignition file based on the one created by openshift-install.
```
filetranspiler -i bootstrap.ign -f bootstrap -o bootstrap-static.ign
```

Copy the ignition files to webserver.

This process needs to be done all all the nodes in the enviornment.
Example configuration
```
tree /var/www/html/ignition/
├── bootstrap-static.ign
├── master0.ign
├── master1.ign
├── master2.ign
├── worker0.ign
└── worker1.ign

0 directories, 6 files
```

For static deployment you need to press tab on the CoreOS installer screen and edit the boot configuration with the following example.
```
ip=192.168.7.20::192.168.7.1:255.255.255.0:bootstrap:enp1s0:none:192.168.7.77
coreos.inst.install_dev=vda
coreos.inst.image_url=http://192.168.7.77:8080/install/rhcos-4.2.0-x86_64-metal-bios.raw.gz
coreos.inst.ignition_url=http://192.168.7.77:8080/ignition/bootstrap-static.ign
```

**Links:**  
* [OpenShift 4.1 Bare Metal Install Quickstart](https://blog.openshift.com/openshift-4-bare-metal-install-quickstart/)
* [Installing a cluster on bare metal](https://docs.openshift.com/container-platform/4.2/installing/installing_bare_metal/installing-bare-metal.html#machine-requirements_installing-bare-metal)
