 #!/bin/bash
 # https://gist.github.com/cdoan1/6ec6a5b3f57764caeb22e015a109e4b7
set -x 
## Variables
export PULL_SECRET_JSON=~/pull_secret.json
export LOCAL_SECRET_JSON=~/merged-pull-secret.json
export PORT=8443 #5000
export REGISTRY_URL=$(hostname)
export LOCAL_REGISTRY=${REGISTRY_URL}:${PORT}
export LOCAL_REPOSITORY=ocp4
#https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt
export OCP_RELEASE=latest # for 4.10 release use latest-4.10
export OCP_REGISTRY=quay.io/openshift-release-dev/ocp-release
export EMAIL="admin@changeme.com"
export PASSWORD="CHANGEME"
export USERNAME="init"
export AUTH="$(echo -n 'init:${PASSWORD}' | base64 -w0)" # in base 64
export TLS_VERIFY=false

## Functional

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

function login_to_registry(){
podman login --authfile ~/merged-pull-secret.json \
  -u ${USERNAME} \
  -p ${PASSWORD} \
  ${LOCAL_REGISTRY} \
  --tls-verify=${TLS_VERIFY} 
}

function ocp_mirror_release() {
    if [ ${TLS_VERIFY} == "false" ];
    then 
       USE_INSECURE="true"
	else
       USE_INSECURE="false"	
    fi 
	oc adm -a ${LOCAL_SECRET_JSON} release mirror \
		--from=${OCP_REGISTRY}:${OCP_RELEASE} \
		--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
		--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE} --insecure=${USE_INSECURE}
}

function download_oc_client() {
	if [[ ! -f /usr/bin/oc ]]; then
		curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
        chmod +x configure-openshift-packages.sh
        ./configure-openshift-packages.sh -i
		#https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt
		export OCP_RELEASE=$(oc version | awk '{print $3}' | head -1)-x86_64
	else 
		export OCP_RELEASE=$(oc version | awk '{print $3}' | head -1)-x86_64
	fi
}

create_merge_secret
login_to_registry
download_oc_client
ocp_mirror_release
