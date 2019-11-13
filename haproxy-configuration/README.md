# Configure HA-Proxy for OpenShift

### Install HA Proxy Package
```
sudo yum install -y haproxy
```

### Configure Firewall rules
```
sudo firewall-cmd --add-port={80/tcp,443/tcp,6443/tcp,22623/tcp,32700/tcp} --permanent
sudo firewall-cmd --reload
```

### Backup haproxy config
```
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

### edit haproxy config

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
    server worker-01 worker-01.ocp4.example.com:443 check
    server worker-02 worker-02.ocp4.example.com:443 check

frontend router_http
    mode http
    option httplog
    bind 0.0.0.0:80
    default_backend router_http

backend router_http
    mode http
    balance roundrobin
    server worker-01 worker-01.ocp4.example.com:80 check
    server worker-02 worker-02.ocp4.example.com:80 check
```

### Set semanage ports for selinux
```
sudo semanage port  -a 22623 -t http_port_t -p tcp
sudo semanage port  -a 6443 -t http_port_t -p tcp
sudo semanage port  -a 32700 -t http_port_t -p tcp
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
