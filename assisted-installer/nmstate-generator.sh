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
        dns_entries=$(generateDNSServerEntries 4)
        interface_name=$(_jq '.ipv4.iface')
        static_ipv4_address=$(_jq '.ipv4.address')
        static_ipv4_prefix=$(_jq '.ipv4.prefix')
        auto_dns=${USE_AUTO_DNS}
        echo ${dns_entries}
        echo ${interface_name}
        echo ${static_ipv4_address}
        echo ${static_ipv4_prefix}
      done
