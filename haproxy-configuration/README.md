# Configure HA-Proxy for OpenShift

### Install HA Proxy Package
```
sudo yum install -y haproxy
```


### Configure Firewall rules
```
sudo firewall-cmd --add-port={80/tcp,443/tcp,6443/tcp,22623/tcp,32700/tcp,1936/tcp} --permanent
sudo firewall-cmd --reload
```

### Backup haproxy config
```
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

### edit haproxy config
* View haproxy-tcp.cfg and edit config
* [haproxy-tcp.cfg](https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/haproxy-configuration/haproxy-tcp.cfg)


### Set semanage ports for selinux
```
sudo semanage port  -a 22623 -t http_port_t -p tcp
sudo semanage port  -a 6443 -t http_port_t -p tcp
sudo semanage port  -a 32700 -t http_port_t -p tcp
sudo semanage port  -a 1936 -t http_port_t -p tcp
sudo semanage port  -l  | grep -w http_port_t
```

### Test Haproxy service
```
systemctl start haproxy
systemctl status haproxy
```

### Enable the haproxy service
```
systemctl enable haproxy
```

### Notes
* If your machine is using mutiple interfaces review the link below. 
[https://stackoverflow.com/questions/34793885/haproxy-cannot-bind-socket-0-0-0-08888](https://stackoverflow.com/questions/34793885/haproxy-cannot-bind-socket-0-0-0-08888)
* Example Stats URL 
  *  `http://haproxy-ip-address:1936/haproxy?stats`
  * username and password `admin:password`

