# OpenShift helper node 
The OpenShift Helper node termed by Christian Hernandez contains all the software needed to get a OpenShift 4.x deployment going. 

This will show who to setup a helper node manually. There is a ansible playbook written Christian below. 

The helpernode will server as yout LB/DHCP/PXE/DNS and HTTPD server.

**Assumptions**  
1. The machine has access to the internet.
2. The network does no have DHCP

**Hardware Recommendations**  
* 4 vCPUS 
* 4 GB of RAM 
* 40 GB HD
* Static IP 

**Configure a RHEL 7 machine**  
I have not tested this on RHEL 8 and am open to feedback. 

**Install and configure firewalld**  
```
sudo yum install firewalld -y 
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo  systemctl status firewalld
```

**Configure DHCP**  
[DHCP Server Configuration](dhcp-configuration/)  

**Configure DNS**  
[DNS Configuration](dns-server-configuration/) 

**Configure WebServer**  
[Web (HTTP) server Configuration](webserver-configuration/)  

**Configure PXE**  
[PXE Configuration](pxe-configuration/)  

**Configure HAPROXY**  
[HAProxy Configuration](haproxy-configuration/)  


**Copy ignition files to helpernode**  
This should be followed after you have the openshift install files and config file on this machine or a remote machine. 

**create iginition file directory**  
```
$ export OC_VERSION="4.2"

$ sudo mkdir /var/www/html/openshift4/${OC_VERSION}/ignitions
$ cd /var/www/html/openshift4/${OC_VERSION}/ignitions
```

**If your files where generated on a remote box run the following**
```
$ cd /var/www/html/openshift4/${OC_VERSION}/ignitions
$ sudo scp -r  username@remotebox:/home/username/ocp4/*.ign .
$ restorecon -RFv /var/www/html/
```

**If your files where generated locally run the following**
```
$ cd /var/www/html/openshift4/${OC_VERSION}/ignitions
$ cp -avi  /home/username/ocp4/*.ign .
$ restorecon -RFv /var/www/html/
```

**Link:**
[ocp4-upi-helpernode](https://github.com/christianh814/ocp4-upi-helpernode)