#!/bin/bash 
set -xe 
export INTERNAL_REGISTRY=registry.example.com
export PULL_SECRET_JSON=~/pull-secret.json
export LOCAL_SECRET_JSON=~/merged-pull-secret.json
export OPENSHIFT_VERSION="4.10"
export PORT=8443
export LOCAL_REGISTRY=${INTERNAL_REGISTRY}:${PORT}
export LOCAL_REPOSITORY=olm-mirror
export TLS_VERIFY=false
export EMAIL="admin@changeme.com"
export PASSWORD="CHANGEME"
export USERNAME="init"
export AUTH="$(echo -n 'init:${PASSWORD}' | base64 -w0)" # in base 64

if [ ! -f /usr/local/bin/grpcurl ];
then 
    curl -OL https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz
    tar -zxvf grpcurl_1.8.6_linux_x86_64.tar.gz
    sudo mv grpcurl /usr/local/bin/
fi

if [ ! -f /usr/local/bin/opm ];
then 
    curl -OL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-${OPENSHIFT_VERSION}/opm-linux.tar.gz
    tar -zxvf opm-linux.tar.gz
    sudo mv opm /usr/local/bin 
fi 

function create_merge_secret(){
    if [ -f ${PULL_SECRET_JSON} ];
    then 

        cat <<EOF > ~/reg-secret.txt
"${LOCAL_REGISTRY}": {
    "email":  "${EMAIL}",
    "auth": "${AUTH}"
}
EOF

        cat ${PULL_SECRET_JSON} |jq ".auths += {`cat ~/reg-secret.txt`}"|tr -d '[:space:]' > ${LOCAL_SECRET_JSON}
    else
        echo "${PULL_SECRET_JSON} not found please add"
        echo "Plese go to https://console.redhat.com/openshift/install/"
        exit 
    fi  
}

create_merge_secret
oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

REDHAT_CREDS=$(cat ${PULL_SECRET_JSON} | jq .auths.\"registry.redhat.io\".auth -r | base64 -d)
RHN_USER=$(echo $REDHAT_CREDS | cut -d: -f1)
RHN_PASSWORD=$(echo $REDHAT_CREDS | cut -d: -f2)
podman login -u "$RHN_USER" -p "$RHN_PASSWORD" registry.redhat.io

podman  login ${LOCAL_REGISTRY}  -u ${USERNAME} -p ${PASSWORD}  --tls-verify=${TLS_VERIFY}

podman run -p50051:50051 -d -it registry.redhat.io/redhat/redhat-operator-index:v${OPENSHIFT_VERSION}
sleep 15s
rm -rf packages.out saved-packages.log
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out

cat packages.out | grep -E 'local-storage|odf-*|ocs|openshift-gitops-operator|advanced-cluster-management|ansible-automation-platform-operator|cincinnati-operator|klusterlet-product|mcg-operator|multicluster-engine|openshift-pipelines-operator-rh|quay-operator'  | awk '{print $2}' | tr '"' ' '  | sed 's/ //g' | tee -a saved-packages.log

opm index prune \
    -f registry.redhat.io/redhat/redhat-operator-index:v${OPENSHIFT_VERSION} \
    -p $(cat saved-packages.log | paste -d ',' -s) \
    -t ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/redhat-operator-index:v${OPENSHIFT_VERSION}

podman login --authfile ${LOCAL_SECRET_JSON} \
  ${LOCAL_REGISTRY} \
  --tls-verify=${TLS_VERIFY} 
podman push ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/redhat-operator-index:v${OPENSHIFT_VERSION}


oc adm catalog mirror  ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/redhat-operator-index:v${OPENSHIFT_VERSION}  ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} -a ${LOCAL_SECRET_JSON}

cd manifests-redhat-operator-index-*   
oc create -f imageContentSourcePolicy.yaml
oc create -f catalogSource.yaml 
oc get pods -n openshift-marketplace

sudo podman stop $(sudo podman ps -a | grep redhat-operator-index | awk '{print $1}')
sudo podman rm  $(sudo podman ps -a | grep redhat-operator-index | awk '{print $1}')
rm -rf manifests-redhat-operator-index-*
