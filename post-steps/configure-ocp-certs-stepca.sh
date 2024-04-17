#!/bin/bash
# https://ypbind.de/maus/notes/real_life_step-ca_with_multiple_users/
# Define variables

# Check if logged into OpenShift
if ! oc whoami &> /dev/null; then
    echo "Not logged into OpenShift. Exiting..."
    exit 1
fi

# interface_name="System eth0"
# ip_address=192.168.130.66
# sudo nmcli connection modify  "${interface_name}"  ipv4.dns $ip_address,147.75.207.207
# sudo nmcli connection down "${interface_name}" && sudo nmcli connection up "${interface_name}"
# list the dns information using nmcli 
# sudo nmcli connection show "${interface_name}" | grep ipv4.dns
export CERTDIR="$HOME/certdir" # Update this to your desired certificate storage directory
export CERTNAME="testing"
export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export LE_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
echo "LE_API: ${LE_API}"
echo "LE_WILDCARD: ${LE_WILDCARD}"

if [[ ! -d $CERTDIR ]]; then
    mkdir -p $CERTDIR
fi


if [[ ! -f $HOME/root_ca.crt ]]; then
    step ca root root_ca.crt
fi

# Ensure variables are set
if [[ -z "$LE_API" || -z "$LE_WILDCARD" ]]; then
    echo "Failed to set LE_API or LE_WILDCARD."
    exit 1
fi

# Step 1: Generate certificates using step CA
TOKEN=$(step ca token *.${LE_WILDCARD})
step ca certificate --token $TOKEN --not-after=1440h *.${LE_WILDCARD} ${LE_WILDCARD}.crt ${LE_WILDCARD}.key
TOKEN=$(step ca token ${LE_API})
step ca certificate --token $TOKEN --not-after=1440h ${LE_API} ${LE_API}.crt ${LE_API}.key

openssl x509 -in ${LE_WILDCARD}.crt -text -noout || exit $?

read -p "Press enter to continue"

# Step 2: Create a secret for the router certificate
oc create secret tls router-certs --cert=${LE_WILDCARD}.crt --key=${LE_WILDCARD}.key -n openshift-ingress 

# Step 3: Update the OpenShift router CR
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'

# Step 4: Verify the certificate by checking the router pods
oc get po -n openshift-ingress

# Step 5: Flatten the oc config view and save it
oc config view --flatten > kubeconfig-newapi

openssl x509 -in${LE_API}.crt -text -noout

# Step 6: Create another secret for the API certificate
oc create secret tls api-cert --cert=${LE_API}.crt --key=${LE_API}.key -n openshift-config

# Step 7: Update the API server with the new certificate
oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates":[{"names": ["'${LE_API}'"], "servingCertificate": {"name": "api-cert"}}]}}}'

# Step 8: Verify the update
oc get apiserver cluster -o yaml
oc get clusteroperators kube-apiserver

oc create configmap custom-ca --from-file=ca-bundle.crt=.step/certs/root_ca.crt  -n openshift-config
oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'

sudo cp root_ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust extract



