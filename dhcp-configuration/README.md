# DHCP Configuration for OpenShift 4

The DHCP Server is used to assign coreos nodes with the correct ip address. Note the machine name below will name the RHCOS machine with the name name upon boot. 



**Install dhcp package**
```
sudo yum install -y  dhcp-server
```

**Update dhcp.conf file**
```
authoritative;
ddns-update-style interim;
default-lease-time 14400;
max-lease-time 14400;

option routers                  192.168.1.1;
option broadcast-address        192.168.1.255;
option subnet-mask              255.255.255.0;
option domain-name-servers      192.168.1.245; # your dns server
option domain-name              "example.com"; # your domain fqdn


subnet 192.168.1.0 netmask 255.255.255.0 {
   	pool {
      	range 192.168.1.75 192.168.1.90; # this can be changed to the range you would like dhcp to use

      	# Static entries
      	host bootstrap-0 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.76; }
      	host master-01 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.77; }
      	host master-02 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.78; }
      	host master-03 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.79; }
      	host worker-01 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.80; }
      	host worker-02 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.81; }

      	# this will not give out addresses to hosts not listed above
      	deny unknown-clients;

      	# this is PXE specific
      	filename "pxelinux.0";
      	next-server 192.168.1.80; # your PXE Server 
         	}
}

```

**Start the dhcpd service**
```
sudo systemctl start dhcpd
```

**Check the status of the dhcp process**
```
sudo systemctl status dhcpd
```