#!/bin/bash
# https://ksingh7.medium.com/lets-automate-let-s-encrypt-tls-certs-for-openshift-4-211d6c081875
# https://docs.openshift.com/container-platform/4.12/security/certificates/api-server.html

# Clone the acmesh-official repository
if [ ! -d $HOME/acme.sh ]; then
   cd $HOME
    git clone https://github.com/acmesh-official/acme.sh.git
    cd acme.sh
fi
if [ $# -ne 3 ]; then
    echo "Usage: $0 <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <EMAIL>"
    exit 1
fi

# Export the AWS access key ID and secret access key
export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export EMAIL=$3



#!/bin/bash 
# Export the Let's Encrypt API and wildcard domain
export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export LE_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
echo "LE_API: ${LE_API}" || exit 1
echo "LE_WILDCARD: ${LE_WILDCARD}" || exit 1
#docker run --rm -it --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -v "/etc/letsencrypt:/etc/letsencrypt" certbot/dns-route53 certonly --dns-route53  -d ${LE_API} -d *.${LE_WILDCARD}  --agree-tos


# Issue a certificate using acme.sh
 ./acme.sh --register-account -m ${EMAIL}

${HOME}/acme.sh/acme.sh --issue -d ${LE_API} -d *.${LE_WILDCARD} --dns dns_aws

# Create a directory for the certificates
export CERTDIR=$HOME/certificates
mkdir -p ${CERTDIR}

# Install the certificate
${HOME}/acme.sh/acme.sh --install-cert -d ${LE_API} -d *.${LE_WILDCARD} --cert-file ${CERTDIR}/cert.pem --key-file ${CERTDIR}/key.pem --fullchain-file ${CERTDIR}/fullchain.pem --ca-file ${CERTDIR}/ca.cer

# Create a secret for the router certificate
oc create secret tls router-certs --cert=${CERTDIR}/fullchain.pem --key=${CERTDIR}/key.pem -n openshift-ingress

# Update the OpenShift router CR
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'

# Verify the certificate by checking the router pods
oc get po -n openshift-ingress

 oc config view --flatten > kubeconfig-newapi

oc create secret tls api-cert \
    --cert=${CERTDIR}/fullchain.pem \
    --key=${CERTDIR}/privkey.pem \
    -n openshift-config

oc patch apiserver cluster \
     --type=merge -p \
     '{"spec":{"servingCerts": {"namedCertificates":
     [{"names": ["'${LE_API}'"], 
     "servingCertificate": {"name": "api-cert"}}]}}}'

oc get apiserver cluster -o yaml

oc get clusteroperators kube-apiserver
