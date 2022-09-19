#!/bin/bash -e

export REGISTRY_NAME=harbor-registry
export DOMAIN=gp.ocpincubator.com

mkdir -p /data/cert/
mkdir -p /etc/docker/certs.d/${DOMAIN}/
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Georgia/L=Atlanta/O=example/OU=LAB/CN=${DOMAIN}" \
 -key ca.key \
 -out ca.crt
openssl genrsa -out ${DOMAIN}.key 4096
openssl req -sha512 -new \
    -subj  "/C=CN/ST=Georgia/L=Atlanta/O=example/OU=LAB/CN=${DOMAIN}" \
    -key ${DOMAIN}.key \
    -out ${DOMAIN}.csr
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=${REGISTRY_NAME}.${DOMAIN}
DNS.2=${REGISTRY_NAME}
DNS.3=${HOSTNAME}
DNS.4=${DOMAIN}
EOF
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in ${DOMAIN}.csr \
    -out ${DOMAIN}.crt

cp ${DOMAIN}.crt /data/cert/
cp ${DOMAIN}.key /data/cert/
openssl x509 -inform PEM -in ${DOMAIN}.crt -out ${DOMAIN}.cert
cp ${DOMAIN}.cert /etc/docker/certs.d/${DOMAIN}/
cp ${DOMAIN}.key /etc/docker/certs.d/${DOMAIN}/
cp ca.crt /etc/docker/certs.d/${DOMAIN}/
systemctl restart docker


#cp harbor.yml.tmpl harbor.yml
#sed -i 's/reg.mydomain.com/'e'/g' harbor.yml