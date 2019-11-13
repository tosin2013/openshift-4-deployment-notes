# Configure PXE TFTP SERVER for OpenShift 4 Deployment

When provisioing a bare metal cluster a PXE Server is needed. As your machine boots your machine will use DHCP on the network to then boot to the pxe server. This will allow your coreos machine to download the appropriate image to boot from and start the installation of the operating system. 

**Install Required Packages**
```
sudo yum install -y   tftp-server
```

**Configure Firewall Rules**
```
sudo firewall-cmd --add-service=tftp --permanent
sudo firewall-cmd --reload
```

**Configure pxe settings**
1. Update the oc-env file
2. run the `sudo ./configure-pxe-server.sh` script
