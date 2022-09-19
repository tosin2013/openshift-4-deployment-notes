#!/bin/bash

# Variables
export PULL_SECRET_JSON=~/pull_secret.json
export LOCAL_SECRET_JSON=~/merged-pull-secret.json
export PORT=8443 #5000
export REGISTRY_URL=$(hostname)
export LOCAL_REGISTRY=${REGISTRY_URL}:${PORT}
export LOCAL_REPOSITORY=ocp4
export OCP_REGISTRY=quay.io/openshift-release-dev/ocp-release
export EMAIL="admin@changeme.com"
export PASSWORD="CHANGEME"
export USERNAME="init"
export AUTH="$(echo -n 'init:${PASSWORD}' | base64 -w0)" # in base 64
export TLS_VERIFY=false
export VERSION=latest # for 4.10 release use latest-4.10

# Functional

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
    echo "----> Mirroring OCP Release: ${OCP_RELEASE}"
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
	podman pull quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE} 
	podman tag quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE}  mirrorvm.lab.tosins-edgelab.io:8443/ocp4:${OCP_RELEASE} 
	podman push mirrorvm.lab.tosins-edgelab.io:8443/ocp4:${OCP_RELEASE}  --authfile ~/merged-pull-secret.json --tls-verify=false
}

function download_oc_latest_client() {
	if [[ ! -f /usr/bin/oc ]]; then
		curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
        chmod +x configure-openshift-packages.sh
        ./configure-openshift-packages.sh -i
		#https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt

		if [ -f ${HOME}/cluster-versions.json ];
		then 
			VARIABLE=$(oc version | awk '{print $3}' | head -1)
			AI_OC_RELEASE=$(cat ${HOME}/cluster-versions.json | jq '.[]|.display_name'  | grep ${VARIABLE} | head -1 | tr -d '"')
			export OCP_RELEASE=${AI_OC_RELEASE}-x86_64
		else 
			export OCP_RELEASE=$(oc version | awk '{print $3}' | head -1)-x86_64
		fi 	
	else 
		if [ -f ${HOME}/cluster-versions.json ];
		then 
			VARIABLE=$(oc version | awk '{print $3}' | head -1)
			AI_OC_RELEASE=$(cat ${HOME}/cluster-versions.json  | jq '.[]|.display_name'  | grep ${VARIABLE} | head -1 | tr -d '"')
			export OCP_RELEASE=${AI_OC_RELEASE}-x86_64
		else 
			export OCP_RELEASE=$(oc version | awk '{print $3}' | head -1)-x86_64
		fi 
	fi
}


function download_ipi_installer() {
	echo "----> Downloading IPI Installer"
	oc adm --registry-config ${PULL_SECRET_JSON} release extract \
		--command=openshift-baremetal-install \
		--from=${OCP_REGISTRY}:${OCP_RELEASE} \
		--to .

	if [[ ! -f openshift-baremetal-install ]]; then
		echo "OCP Installer wasn't extracted, exiting..."
		exit 1
	fi

	sudo mv openshift-baremetal-install /usr/bin/openshift-baremetal-install
}

function download_rhcos() {
	export RHCOS_VERSION=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["release"]')
	export RHCOS_ISO_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["formats"]["iso"]["disk"]["location"]')
	export RHCOS_ROOT_FS=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["formats"]["pxe"]["rootfs"]["location"]')
	export RHCOS_QEMU_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["qemu"]["formats"]["qcow2.gz"]["disk"]["location"]')
	export RHCOS_QEMU_SHA_UNCOMPRESSED=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["qemu"]["formats"]["qcow2.gz"]["disk"]["uncompressed-sha256"]')
	export RHCOS_OPENSTACK_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["openstack"]["formats"]["qcow2.gz"]["disk"]["location"]')
	export RHCOS_OPENSTACK_SHA_COMPRESSED=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["openstack"]["formats"]["qcow2.gz"]["disk"]["sha256"]')
	export OCP_RELEASE_DOWN_PATH=/var/www/html/$OCP_RELEASE

	echo "RHCOS_VERSION: $RHCOS_VERSION"
	echo "RHCOS_OPENSTACK_URI: $RHCOS_OPENSTACK_URI"
	echo "RHCOS_OPENSTACK_SHA_COMPRESSED: ${RHCOS_OPENSTACK_SHA_COMPRESSED}"
	echo "RHCOS_QEMU_URI: $RHCOS_QEMU_URI"
	echo "RHCOS_QEMU_SHA_UNCOMPRESSED: $RHCOS_QEMU_SHA_UNCOMPRESSED"
	echo "RHCOS_ISO_URI: $RHCOS_ISO_URI"
	echo "RHCOS_ROOT_FS: $RHCOS_ROOT_FS"
	#echo "Press Enter to continue or Ctrl-C to cancel download"
	#read

	if [[ ! -d ${OCP_RELEASE_DOWN_PATH} ]]; then
		echo "----> Downloading RHCOS resources to ${OCP_RELEASE_DOWN_PATH}"
		sudo mkdir -p ${OCP_RELEASE_DOWN_PATH}
		echo "--> Downloading RHCOS resources: RHCOS QEMU Image"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_QEMU_URI | xargs basename) ${RHCOS_QEMU_URI}
		echo "--> Downloading RHCOS resources: RHCOS Openstack Image"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_OPENSTACK_URI | xargs basename) ${RHCOS_OPENSTACK_URI}
		echo "--> Downloading RHCOS resources: RHCOS ISO"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_ISO_URI | xargs basename) ${RHCOS_ISO_URI}
		echo "--> Downloading RHCOS resources: RHCOS RootFS"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_ROOT_FS | xargs basename) ${RHCOS_ROOT_FS}
	else
		echo "The folder already exist, so delete it if you want to re-download the RHCOS resources"
	fi
}

function format_images_config() {
	echo """
      Add the following to install-config.yaml

        bootstrapOSImage: http://$(hostname --long)/$OCP_RELEASE/${RHCOS_QEMU_URI##*/}?sha256=$RHCOS_QEMU_SHA_UNCOMPRESSED
        clusterOSImage: http://$(hostname --long)/$OCP_RELEASE/${RHCOS_OPENSTACK_URI##*/}?sha256=$RHCOS_OPENSTACK_SHA_COMPRESSED
     """
}

function configure_webserver(){
    sudo yum install -y  syslinux httpd wget
	sudo systemctl enable firewalld
	sudo systemctl start firewalld
    sudo firewall-cmd --add-service={http,https} --permanent
    sudo firewall-cmd --add-port=8080/tcp --permanent
    sudo firewall-cmd --reload
    sed 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
    sudo systemctl restart httpd
}

#sudo scp utilityvm.example.com:/opt/registry/certs/ca.pem /etc/pki/ca-trust/source/anchors
#sudo update-ca-trust
#curl -u openshift:redhat https://utilityvm.example.com:5000/v2/_catalog
create_merge_secret
login_to_registry
download_oc_latest_client
ocp_mirror_release
configure_webserver
download_ipi_installer
download_rhcos
format_images_config
