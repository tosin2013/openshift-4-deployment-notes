#!/bin/bash

set -e

echo -e "\n===== Generating NMState Configuration files..."

NODE_LENGTH=$(echo "${NODE_CFGS}" | jq -r '.nodes | length')
echo "  Working with ${NODE_LENGTH} nodes..."

#########################################################
## Functions
function generateDNSServerEntries() {
  SPACES=""
  SPACE_COUNT=$1
  while [ $SPACE_COUNT -gt 0 ]; do
    SPACES="$SPACES "
    SPACE_COUNT=$(($SPACE_COUNT-1))
  done
  for isrv in ${CLUSTER_NODE_NET_DNS_SERVERS[@]}; do 
    echo "${SPACES}- $isrv"
  done
}

for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }
  echo "  Creating NMState config for $(_jq '.name')..."

  if [ $MULTI_NETWORK  == false && $USE_DHCP == false ];
  then 
    cat << EOF > ${CLUSTER_DIR}/$(_jq '.name').yaml
dns-resolver:
  config:
    server:
$(generateDNSServerEntries 4)
interfaces:
- name: $(_jq '.ipv4.iface')
  ipv4:
    address:
    - ip: $(_jq '.ipv4.address')
      prefix-length: $(_jq '.ipv4.prefix')
    dhcp: false
    enabled: true
  state: up
  type: ethernet
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: $(_jq '.ipv4.gateway')
    next-hop-interface: $(_jq '.ipv4.iface')
    table-id: 254
EOF
  elif [ $MULTI_NETWORK == false && $USE_DHCP == true ];
  then 
      cat << EOF > ${CLUSTER_DIR}/$(_jq '.name').yaml
dns-resolver:
  config:
    server:
$(generateDNSServerEntries 4)
interfaces:
- name: $(_jq '.ipv4.iface')
  ipv4:
    auto-dns: false
    dhcp: true
    enabled: true
  state: up
  type: ethernet
EOF
  elif [ $MULTI_NETWORK == true && $USE_DHCP == true ];
  then 
    cat << EOF > ${CLUSTER_DIR}/$(_jq '.name').yaml
dns-resolver:
  config:
    server:
$(generateDNSServerEntries 4)
interfaces:
- name: $(_jq '.ipv4_int1.iface')
  ipv4:
    auto-dns: false
    dhcp: true
    enabled: true
  state: up
  type: ethernet
- name: $(_jq '.ipv4_int2.iface')
  ipv4:
    auto-dns: false
    dhcp: true
    enabled: true
  state: up
  type: ethernet
EOF
  elif [ $MULTI_NETWORK == true && $USE_DHCP == false ];
  then 
    cat << EOF > ${CLUSTER_DIR}/$(_jq '.name').yaml
dns-resolver:
  config:
    server:
$(generateDNSServerEntries 4)
interfaces:
- name: $(_jq '.ipv4_int1.iface')
  ipv4:
    address:
    - ip: $(_jq '.ipv4_int1.address')
      prefix-length: $(_jq '.ipv4_int1.prefix')
    dhcp: false
    enabled: true
  state: up
  type: ethernet
- name: $(_jq '.ipv4_int2.iface')
  ipv4:
    address:
    - ip: $(_jq '.ipv4_int2.address')
      prefix-length: $(_jq '.ipv4_int2.prefix')
    dhcp: false
    enabled: true
  state: up
  type: ethernet
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: $(_jq '.ipv4_int1.gateway')
    next-hop-interface: $(_jq '.ipv4_int1.iface')
    table-id: 254
EOF
  fi

done
