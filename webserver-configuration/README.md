# Configure Web Server Instructions for OpenShift 4.x

**Install required packages**
```
sudo yum install -y  syslinux httpd wget
```

**Configure Firewall Rules**
```
sudo firewall-cmd --add-service={http,http} --permanent
sudo firewall-cmd --add-port={8080/tcp} --permanent
sudo firewall-cmd --reload
```

**Configure webserver of OpenShift 4.x deployments**
1. update /etc/httpd/conf/httpd.conf
   1. `Listen 8080`
2. sudo systemctl restart httpd
3. run the rhcos-webserver-provisioning.sh  script
```
./rhcos-webserver-provisioning.sh ga #for latest GA builds
./rhcos-webserver-provisioning.sh nightly #for latest nightly builds
```
