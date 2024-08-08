## Automating Let's Encrypt TLS Certificates for OpenShift 4.16

In this detailed how-to guide, we'll walk through a script designed to automate the generation and installation of Let's Encrypt TLS certificates for OpenShift 4.16. This guide assumes you are familiar with basic OpenShift operations and have access to a running OpenShift cluster.

[Full Script](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/create_custom_cert.sh)

### Prerequisites

- An OpenShift 4.16 cluster.
- AWS credentials with the necessary permissions.
- An email address for Let's Encrypt account registration.

### Step 1: Setting Up the Environment

First, we need to clone the `acme.sh` repository if it doesn't already exist in the home directory:

```bash
#!/bin/bash

if [ ! -d $HOME/acme.sh ]; then
   cd $HOME
   git clone https://github.com/acmesh-official/acme.sh.git
   cd acme.sh
fi
```

### Step 2: Provide AWS Credentials and Email

Ensure the script receives exactly three arguments: AWS Access Key ID, AWS Secret Access Key, and an email address. If not, the script will exit with an error:

```bash
if [ $# -ne 3 ]; then
    echo "Usage: $0 <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <EMAIL>"
    exit 1
fi

export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export EMAIL=$3
```

### Step 3: Define OpenShift Variables

We need to extract the OpenShift API server and wildcard domain for Let's Encrypt:

```bash
export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export LE_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
echo "LE_API: ${LE_API}" || exit 1
echo "LE_WILDCARD: ${LE_WILDCARD}" || exit 1
```

### Step 4: Register and Issue Certificates

Register an account with Let's Encrypt and issue the certificates using `acme.sh`:

```bash
./acme.sh --register-account -m ${EMAIL}
${HOME}/acme.sh/acme.sh --issue -d ${LE_API} -d *.${LE_WILDCARD} --dns dns_aws
```

### Step 5: Install the Certificates

Create a directory for the certificates and install them:

```bash
export CERTDIR=$HOME/certificates
mkdir -p ${CERTDIR}
${HOME}/acme.sh/acme.sh --install-cert -d ${LE_API} -d *.${LE_WILDCARD} --cert-file ${CERTDIR}/cert.pem --key-file ${CERTDIR}/key.pem --fullchain-file ${CERTDIR}/fullchain.pem --ca-file ${CERTDIR}/ca.cer
```

### Step 6: Update Router Certificates

Create a secret for the router certificate and patch the OpenShift router configuration:

```bash
oc create secret tls router-certs --cert=${CERTDIR}/fullchain.pem --key=${CERTDIR}/key.pem -n openshift-ingress
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'
oc get po -n openshift-ingress
```

### Step 7: Update API Server Certificates

Create a secret for the API server and patch the API server configuration:

```bash
oc config view --flatten > kubeconfig-newapi
oc create secret tls api-cert --cert=${CERTDIR}/fullchain.pem --key=${CERTDIR}/privkey.pem -n openshift-config

oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates":[{"names": ["'${LE_API}'"], "servingCertificate": {"name": "api-cert"}}]}}}'
oc get apiserver cluster -o yaml
oc get clusteroperators kube-apiserver
```

### Conclusion

By following these steps, you automate the process of obtaining and installing Let's Encrypt TLS certificates for your OpenShift 4.16 cluster. This enhances your cluster's security by ensuring all communications are encrypted.

### Additional Resources

For more information, refer to the following OpenShift 4.16 documentation:

- [Configuring the API Server Certificates](https://docs.openshift.com/container-platform/4.16/security/certificates/api-server.html)
- [Ingress Controller Configuration](https://docs.openshift.com/container-platform/4.16/networking/ingress-operator.html)
- [Let’s Automate :: Let’s Encrypt TLS Certs for OpenShift 4](https://ksingh7.medium.com/lets-automate-let-s-encrypt-tls-certs-for-openshift-4-211d6c081875)
