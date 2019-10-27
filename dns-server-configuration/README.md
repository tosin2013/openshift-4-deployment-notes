# Configure Bind Server For OpenShift 4 Deployments
The DNS Server is used for communication between the RHCOS Nodes.

**install bind server packages**
```
sudo yum -y install bind bind-utils
```

**Configure firewall rules**
```
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload
```

**Modifiy your named.conf**
```
$cat /etc/named.conf
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html


acl internal_nets { 192.168.1.0/24; };

options {
	listen-on port 53 { 127.0.0.1; 192.168.1.211; };
	listen-on-v6 port 53 { none; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query { localhost; internal_nets; };

	/*
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable
	   recursion.
	 - If your recursive DNS server has a public IP address, you MUST enable access
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface
	*/
	recursion yes;
	allow-recursion { localhost; internal_nets; };

	dnssec-enable yes;
	dnssec-validation no;

	forwarders { 8.8.8.8; 1.1.1.1; };

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.root.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
        check-names master ignore;
        check-names slave ignore;
        check-names response ignore;
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "ocp4.example.com" IN  {
  type master;
  file "ocp4.example.com.zone";
  allow-query { any; };
  allow-transfer { none; };
  allow-update { none; };
};

zone "1.168.192.in-addr.arpa" {
  type master;
  file "1.168.192.in-addr.arpa.zone";
  allow-query { any; };
  allow-transfer { none; };
  allow-update { none; };
};

```

**Create zone file**
```
$ cat /var/named/ocp4.example.com.zone
$ORIGIN ocp4.example.com.
$TTL 900
@ IN SOA dns.ocp4.example.com. root.ocp4.example.com. (
2019062002 1D 1H 1W 3H
)
@ IN NS dns.ocp4.example.com.

root IN A 192.168.1.211
dns  IN A 192.168.1.211
bootstrap-0        IN  A   192.168.1.76
master-01           IN  A   192.168.1.77
master-02           IN  A   192.168.1.78
master-03           IN  A   192.168.1.79
etcd-0           IN  A   192.168.1.77
etcd-1           IN  A   192.168.1.78
etcd-2           IN  A   192.168.1.79
api              IN  A   192.168.1.211
api-int          IN  A   192.168.1.211
*.apps           IN  A   192.168.1.211
worker-01           IN  A   192.168.1.80
worker-02           IN  A   192.168.1.81
_etcd-server-ssl._tcp   IN  SRV 0 10    2380 etcd-0.ocp4.example.com.
_etcd-server-ssl._tcp     IN      SRV     0 10    2380 etcd-1.ocp4.example.com.
_etcd-server-ssl._tcp     IN      SRV     0 10    2380 etcd-2.ocp4.example.com.
```

**Create reverse zone file**
```
$ cat /var/named/1.168.192.in-addr.arpa.zone
$TTL 900
@ IN SOA bastion.ocp4.example.com. hostmaster.ocp4.example.com. (

2019062001 1D 1H 1W 3H

)

@ IN NS bastion.ocp4.example.com.

77 IN PTR master-01.ocp4.example.com.
78 IN PTR master-02.ocp4.example.com.
79 IN PTR master-03.ocp4.example.com.
80 IN PTR worker-01.ocp4.example.com.
81 IN PTR worker-02.ocp4.example.com.
76 IN PTR bootstrap-0.ocp4.example.com.
211 IN PTR dns.ocp4.example.com.
```

**Test the bind server configuration**
```
named-checkconf /etc/named.conf
```

**Start the bind service instance**
```
systemctl start named
```

**Enable the bind service instance**
```
systemctl enable named
```

**Test dns resolution**
```
dig @localhost  etcd-0.ocp4.example.com
```

**Test Reverse pointer**
```
dig @localhost -t srv _etcd-server-ssl._tcp.ocp4.example.com
```
