 #!/usr/bin/env bash
# WIP 

export OCP_RELEASE="4.13"
export MERGED_PULLSECRET="merged-pull-secret.json"
export OCP_PULLSECRET_AUTHFILE="~/${MERGED_PULLSECRET}"
export REGISTRY_NAME=quay.ztp-pipelines.ocpincubator.com
export REGISTRY_PORT=8443
export LOCAL_REGISTRY=$REGISTRY_NAME:$REGISTRY_PORT
export IMAGE_TAG=olm

# Add extra registry keys
sudo curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv https://www.redhat.com/security/data/55A34A82.txt
sudo jq ".transports.docker += {\"registry.redhat.io/redhat/certified-operator-index\": [{\"type\": \"signedBy\",\"keyType\": \"GPGKeys\",\"keyPath\": \"/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv\"}], \"registry.redhat.io/redhat/community-operator-index\": [{\"type\": \"signedBy\",\"keyType\": \"GPGKeys\",\"keyPath\": \"/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv\"}], \"registry.redhat.io/redhat/redhat-marketplace-operator-index\": [{\"type\": \"signedBy\",\"keyType\": \"GPGKeys\",\"keyPath\": \"/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv\"}]}" < /etc/containers/policy.json > /etc/containers/policy.json.new
sudo mv /etc/containers/policy.json.new /etc/containers/policy.json

# Login registries
REGISTRY_USER=init
REGISTRY_PASSWORD=CHANGEME
podman login -u $REGISTRY_USER -p $REGISTRY_PASSWORD $LOCAL_REGISTRY
#podman login registry.redhat.io --authfile ${HOME}/openshift_pull.json
REDHAT_CREDS=$(cat ~/${MERGED_PULLSECRET} | jq .auths.\"registry.redhat.io\".auth -r | base64 -d)
RHN_USER=$(echo $REDHAT_CREDS | cut -d: -f1)
RHN_PASSWORD=$(echo $REDHAT_CREDS | cut -d: -f2)
podman login -u "$RHN_USER" -p "$RHN_PASSWORD" registry.redhat.io

which oc-mirror >/dev/null 2>&1
if [ "$?" != "0" ] ; then
  #curl -OL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/oc-mirror.tar.gz
  curl -OL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.10/oc-mirror.tar.gz
  tar xvzf oc-mirror.tar.gz
  sudo mv oc-mirror /usr/bin/oc-mirror
  sudo chmod +x /usr/bin/oc-mirror
  oc-mirror version
fi

mkdir -p ${HOME}/.docker
cp -f ${HOME}/${MERGED_PULLSECRET} ${HOME}/.docker/config.json

oc mirror init --registry ${LOCAL_REGISTRY}/openshift/oc-mirror > imageset-config.yaml 
oc mirror --config=./imageset-config.yaml docker://${LOCAL_REGISTRY}/openshift

rm -rf ${HOME}/oc-mirror-workspace || true
oc-mirror --config ${HOME}/mirror-config.yaml docker://$LOCAL_REGISTRY
oc apply -f ${HOME}/oc-mirror-workspace/results-*/imageContentSourcePolicy.yaml 2>/dev/null || cp ${HOME}/oc-mirror-workspace/results-*/imageContentSourcePolicy.yaml ${HOME}/manifests
oc apply -f ${HOME}/oc-mirror-workspace/results-*/catalogSource* 2>/dev/null || cp ${HOME}/oc-mirror-workspace/results-*/catalogSource* ${HOME}/manifests


 oc-mirror-workspace/operators.1664245965/manifests-redhat-operator-index

  oc-mirror-workspace/operators.1664246234/manifests-redhat-operator-index
