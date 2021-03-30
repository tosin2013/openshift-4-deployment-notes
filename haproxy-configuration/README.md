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
* Option 1
  * View haproxy-tcp.cfg and edit config
  * [haproxy-tcp.cfg](haproxy-tcp.cfg)

* Option view modify haproxy.cfg below
```
sudo vim /etc/haproxy/haproxy.cfg

global
    log         127.0.0.1 local2 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
    timeout connect         5s
    timeout client          30s
    timeout server          30s
    log                     global

listen  stats
     bind *:1936
     mode            http
     log             global

     maxconn 10

     #clitimeout      100s
     #srvtimeout      100s
     #contimeout      100s
     timeout queue   100s

     stats enable
     stats hide-version
     stats refresh 30s
     stats show-node
     stats auth admin:password
     stats uri  /haproxy?stats
        
frontend kubernetes_api
    bind 0.0.0.0:6443
    default_backend kubernetes_api

backend kubernetes_api
    balance roundrobin
    option ssl-hello-chk
    server bootstrap-0 bootstrap-0.ocp4.example.com:6443 check
    server master-01 master-01.ocp4.example.com:6443 check
    server master-02 master-02.ocp4.example.com:6443 check
    server master-03 master-03.ocp4.example.com:6443 check

frontend machine_config
    bind 0.0.0.0:22623
    default_backend machine_config

backend machine_config
    balance roundrobin
    option ssl-hello-chk
    server bootstrap-0 bootstrap-0.ocp4.example.com:22623 check
    server master-01 master-01.ocp4.example.com:22623 check
    server master-02 master-02.ocp4.example.com:22623 check
    server master-03 master-03.ocp4.example.com:22623 check

frontend router_https
    bind 0.0.0.0:443
    default_backend router_https

backend router_https
    balance roundrobin
    option ssl-hello-chk
    server compute-01 compute-01.ocp4.example.com:443 check
    server compute-02 compute-02.ocp4.example.com:443 check
    
frontend router_http
    mode http
    option httplog
    bind 0.0.0.0:80
    default_backend router_http

backend router_http
    mode http
    balance roundrobin
    server compute-01 compute-01.ocp4.example.com:80 check
    server compute-02 compute-02.ocp4.example.com:80 check
```

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
