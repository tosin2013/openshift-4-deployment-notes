#!/bin/bash
set -x

# Change variables
NET_GW="192.168.3.1"
NET_DNS="192.168.1.70"
NET_IPADDR="192.168.3"
NET_IFACE="enp1s0"
NET_MASK="24"
NET_TID="254"

OCP_NODE="0"
VM_NAME="ocp$OCP_NODE"
STARTING_NET_IP=50
for x in 1 2 3
do
    echo "NODE NAME: VM_NAME=ocp${OCP_NODE}${x}"
    num=$(( $STARTING_NET_IP + $x ))
    echo "${NET_IPADDR}.${num}"
    export NEW_NET_IPADDR="${NET_IPADDR}.${num}"
cat << EOF > ./ocp${OCP_NODE}${x}.yaml
dns-resolver:
  config:
    server:
    - $NET_DNS
interfaces:
- name: $NET_IFACE
  ipv4:
    address:
    - ip: ${NEW_NET_IPADDR}
      prefix-length: $NET_MASK
    dhcp: false
    enabled: true
  state: up
  type: ethernet
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: $NET_GW
    next-hop-interface: $NET_IFACE
    table-id: $NET_TID
EOF
    cat ./ocp${OCP_NODE}${x}.yaml
done


