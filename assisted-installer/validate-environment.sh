#!/bin/bash 
# scripts to validate enviornment
#set -x 

echo "Current CLUSTER_INGRESS_VIP=${CLUSTER_INGRESS_VIP}"
TEST_CLUSTER_INGRESS_VIP=$(dig +short test.apps.${CLUSTER_NAME}.${CLUSTER_BASE_DNS} |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" |  head -1)
if [ ${CLUSTER_INGRESS_VIP} != ${TEST_CLUSTER_INGRESS_VIP} ];
then 
  echo "Please check CLUSTER_INGRESS_VIP"
  echo "Reported CLUSTER_INGRESS_VIP $CLUSTER_INGRESS_VIP "
  echo "Reported CLUSTER_INGRESS_VIP $TEST_CLUSTER_INGRESS_VIP "
  exit
else
   echo "CLUSTER_INGRESS_VIP $CLUSTER_INGRESS_VIP is valid"
fi 

echo "Current CLUSTER_API_VIP=${CLUSTER_API_VIP}"
TEST_CLUSTER_API_VIP=$(dig +short api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS} |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" |  head -1)
if [ ${CLUSTER_API_VIP} != ${TEST_CLUSTER_API_VIP} ];
then 
  echo "Please check CLUSTER_API_VIP"
  echo "Reported CLUSTER_API_VIP $CLUSTER_API_VIP "
  echo "Reported CLUSTER_API_VIP $TEST_CLUSTER_API_VIP "
  exit
else
   echo "CLUSTER_API_VIP $CLUSTER_API_VIP is valid"
fi 
