# Configure Web (HTTP) Server Instructions for OpenShift 4.x
The Webserver is used to store RHCOS images for the pxe server.  The webserver will also store the ignition files needed for the system.  This is a quick setup guide to confiure your webserver. 

**Install required packages**
```
sudo yum install -y  syslinux httpd wget
```

**Configure Firewall Rules**
```
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

**Configure webserver of OpenShift 4.x deployments**
1. update /etc/httpd/conf/httpd.conf
   1. `Listen 8080`
2. sudo systemctl restart httpd
3. run or review\ the rhcos-webserver-provisioning.sh script
```
./rhcos-webserver-provisioning.sh ga #for latest GA builds
./rhcos-webserver-provisioning.sh nightly #for latest nightly builds
```
