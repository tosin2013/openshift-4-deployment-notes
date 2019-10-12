# Configure PXE TFTP SERVER for OpenShift 4 Deployment

**Install Required Packages**
```
sudo yum install -y   tftp-server
```
*Configure Firewall Rules**

```
sudo firewall-cmd --add-service=tftp --permanent
sudo firewall-cmd --reload
```

# Configure pxe settings
1. Update the oc-env file
2. run the `sudo ./configure-pxe-server.sh` script
