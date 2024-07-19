# Testing External networking with MTV

[OpenShift Virtualization Migration Demo](https://demo.redhat.com/catalog?item=babylon-catalog-prod/equinix-metal.virt-migration-demo.prod&utm_source=webapp&utm_medium=share-link)


### SSH into hypervisor
```
ssh user@hostname.com
```

### Deploy vyos router on KVM
```
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/openshift-virt/deploy-vyos-router.sh
chmod +x deploy-vyos-router.sh
./deploy-vyos-router.sh create
```

### Login to the hypervisor via cockpit
* https://hypervisor.98352.dynamic.example.com:9090

### Validate the vyos
**Default username and password**
* username: vyos
* password: vyos
![20240427101101](https://i.imgur.com/FA2rwXB.png)
**Run command : install image**
![20240427101254](https://i.imgur.com/7yLOY8J.png)
---
![20240427101353](https://i.imgur.com/vmXQ8TE.png)
---
![20240427101428](https://i.imgur.com/PHT8DFo.png)
---
![20240427101509](https://i.imgur.com/Tp970x3.png)
`The vm will shut down and you must manually start it`

**Configure External interface**
*if you are using the default kvm network the ip address can be 192.168.123.x*
```bash
$ configure
$ set interfaces ethernet eth0 address 192.168.123.2/24
$ set interfaces ethernet eth0 description Internet-Facing
$ commit
$ save
$ run show interfaces
$ set protocols static route 0.0.0.0/0 next-hop 192.168.123.1
$ commit 
$ run ping 1.1.1.1 interface 192.168.123.2
$ save 
$ exit 
```

**Enable SSH on router**
```bash
$ configure 
$ set service ssh
$ commit 
$ save
$ exit
``` 

**ssh into router**
```bash
$ ls -la vyos-config.sh
$ scp vyos-config.sh vyos@192.168.123.2:/tmp
$ ssh vyos@192.168.123.2
$ vbash  /tmp/vyos-config.sh 
```

**Shutdown and add a additional  interface for all workers**  
*repeat steps for all workers*
![20240716130611](https://i.imgur.com/3HDcvUq.png)
![20240716130652](https://i.imgur.com/WUy0Fed.png)
**Add the 1925 vlan interface**
![20240716130918](https://i.imgur.com/Zfcjeal.png)
![20240717143328](https://i.imgur.com/HgIkPlq.png)
**Double check each worker node to endure enp11s0 has been created before next step**
![20240716132059](https://i.imgur.com/gkLGs89.png)

**Create Network Attachment Definition**
```bash
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: single-nic-vlan1925
spec:
  desiredState:
    interfaces:
      - name: enp11s0
        type: ethernet
        state: up
        ipv4:
          dhcp: false
          enabled: false
      - name: enp11s0.1925
        type: vlan
        state: up
        ipv4:
          dhcp: false
          enabled: false
        vlan:
          base-iface: enp11s0
          id: 1925
      - name: br-1
        type: linux-bridge
        state: up
        bridge:
          options:
            stp:
              enabled: true
          port:
            - name: enp11s0.1925
        ipv4:
          dhcp: false
          enabled: false
    ovn:
      bridge-mappings:
        - localnet: localnet3
          bridge: br-1
          state: present
  nodeSelector:
    node-role.kubernetes.io/worker: ''
```
![20240717145244](https://i.imgur.com/jbqRiHF.png)

**Create network Attachemebt Definition for linux bridge**
```
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: cnv-linux-bridge-vlan-dhcp
  namespace: default
spec:
  config: |-
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-1",
      "isGateway": true,
      "vlan": 1925,
      "ipam": {
        "type": "static",
        "addresses": [
          {
            "address": "192.168.52.3/24",
            "gateway": "192.168.52.1"
          }
        ],
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "dns": {
          "nameservers": ["8.8.8.8"],
          "domain": "example.com",
          "search": ["example.com"]
        }
      }
    }
```
![20240717145329](https://i.imgur.com/NpLI6Gy.png)

## Test Static IP migration on a Windows VM
**Login To vSshpere and clone VM**
Clone winweb01 as a backup
![20240717145837](https://i.imgur.com/ohDBCtw.png)

Start winweb01 and login 
* select option 8 to change the ip address
* enter option 1 and option 1 then option (S) to change the ip address
* 
  ![20240717150316](https://i.imgur.com/fje2iUv.png)
  ![20240718185656](https://i.imgur.com/OoMA35H.png)

## Start VM Migration plan
**Shutdown and remove winweb01 in the vmimported project**
![20240717152950](https://i.imgur.com/ev9wobR.png)
![20240717153211](https://i.imgur.com/PNyUJ2M.png)
![20240717153229](https://i.imgur.com/ouRo6wW.png)

**Select openshift-mtv project**
![20240718190605](https://i.imgur.com/6cCSBZp.png)
**Create Plan**
**Select Vmware**
![20240717151555](https://i.imgur.com/BcRtUMd.png)
**Select virtual machine - winweb01**
![20240717151658](https://i.imgur.com/iNpjTO3.png)
**Name the plan as winweb01-plan**
* `Validate the network is mapped to default/cnv-linux-bridge-vlan-dhcp`
* `Valiudate that vmimported Target namespace is used`
![20240717152711](https://i.imgur.com/VlX6YJo.png)
**Validate the Use system default is enabled**
![20240717152247](https://i.imgur.com/ETZNOMI.png)
`If you do not wnat to perserve the static IPs check the radio button`
![20240717152325](https://i.imgur.com/RVAS3c8.png)
**Start Migration**
![20240717152436](https://i.imgur.com/dxsLj9U.png)
**Check status under Virtual Machines**
![20240717153542](https://i.imgur.com/hkDyGVv.png)
**Wait for plan to complete**
![20240717180741](https://i.imgur.com/xc9BMCs.png) 
**In Windows machine check the network using option 8**
![20240718102726](https://i.imgur.com/w7MR9tW.png)
**Enable pin in Option 4 the Option 3**
![20240718104612](https://i.imgur.com/BLqw1TH.png)
**Exit menu using option 15 and ping the gateway**
![20240718102855](https://i.imgur.com/Lzvinmx.png)

**Ping from Hypervor node**
```
sudo ip route add 192.168.52.0/24 via 192.168.123.2
ping 192.168.52.100
```