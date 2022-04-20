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
        echo -n "  Creating NMState config for $(_jq '.name')..."
        
        export auto_dns=${USE_AUTO_DNS}
        export parse_dns_vars=$( IFS=,; printf '%s' "${CLUSTER_NODE_NET_DNS_SERVERS[*]}" )

        if [ $MULTI_NETWORK  == false ];
        then 
          export interface_name=$(_jq '.ipv4.iface')
          export static_ipv4_address=$(_jq '.ipv4.address')
          export static_ipv4_prefix=$(_jq '.ipv4.prefix')
          export static_ipv4_gateway=$(_jq '.ipv4.gateway')
          export vlan_id=${VLAN_ID}

          if [ $USE_DHCP == false ] && [ $USE_VLAN == false ]; # Single Network static IPS
          then 
            j2 network-templates/single-nic-static.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml
          elif [ $USE_DHCP == true ] && [ $USE_VLAN == false ]; # Single Network VLAN NIC with Static IPS
          then 
            j2 network-templates/single-nic-dhcp.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml
          elif [ $USE_DHCP == false ] && [ $USE_VLAN == true ]; # Single Network VLAN NIC with Static IPS
          then 
            j2 network-templates/single-nic-vlan-static.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml
          elif [ $USE_DHCP == true ] && [ $USE_VLAN == true ]; # DHCP Network VLAN NIC with Static IPS
          then 
            j2 network-templates/single-nic-vlan-dhcp.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml
          fi
        elif [ $MULTI_NETWORK == true ];
        then 
          export interface_one_name=$(_jq '.ipv4_int1.iface')
          export interface_one_address=$(_jq '.ipv4_int1.address')
          export interface_one_prefix=$(_jq '.ipv4_int1.prefix')
          export interface_one_gateway=$(_jq '.ipv4_int1.gateway')
          export interface_two_name=$(_jq '.ipv4_int2.iface')
          export interface_two_address=$(_jq '.ipv4_int2.address')
          export interface_two_prefix=$(_jq '.ipv4_int2.prefix')
          export vlan_id=${VLAN_ID}
          export vlan_id_two=${VLAN_ID_TWO}
          if  [ $USE_DHCP == true ] && [ $USE_VLAN == false ];  # Multi Network DHCP
          then 
            j2 network-templates/mutli-nic-dhcp.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml 
          elif [ $USE_DHCP == false ] && [ $USE_VLAN == false ]; # Multi Network Static IPs
          then 
            j2 network-templates/mutli-nic-static.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml 
          elif [ $USE_DHCP == false ] && [ $USE_VLAN == true ]; # Single Network VLAN NIC with Static IPS
          then 
            j2 network-templates/mutli-nic-vlan-static.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml
          elif [ $USE_DHCP == true ] && [ $USE_VLAN == true ]; # DHCP Network VLAN NIC with Static IPS
          then 
            j2 network-templates/single-nic-vlan-dhcp.j2 | sed '/^$/d' | tee ${CLUSTER_DIR}/$(_jq '.name').yaml
          fi
        fi 

      done
