#!/bin/bash
set -x 
CERT_STATUS=$(oc get csr | grep Pending | awk '{print $6}')
while [ ! -z "$CERT_STATUS" ]; do
    for csr in $(oc -n openshift-machine-api get csr | awk '/Pending/ {print $1}'); do oc adm certificate approve $csr;done
    CERT_STATUS=$(oc get csr | grep Pending | awk '{print $6}')
done

echo "Current Cert Status..."
oc -n openshift-machine-api get csr 