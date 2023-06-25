#!/bin/bash 
# https://access.redhat.com/solutions/6677901

if [ $# -ne 2 ]; then
    echo "Usage: $0 <YOURVCENTERUSERNAME> <YOURVCENTERPASSWORD>"
    exit 1
fi

if [ -f $HOME/vsphere-env ];
then 
    source $HOME/vsphere-env
else
    echo "Please create a file called vsphere-env in your home directory and populate it with the following variables:"
    echo "export SERVER=yourvcenter.example.com"
    echo "export DATACENTER=yourvcenterdatacenter"
    echo "export DEFAULT_DATASTORE=yourvcenterdatastore"
    echo "export FOLDER_NAME=yourvcenterfolder"
    exit 1
fi

export VCENTERUSERNAME=$1
export VCENTERPASSWORD=$2


USERNAME=$(echo -n "$VCENTERUSERNAME" | base64 -w0)
PASSWORD=$(echo -n "$VCENTERPASSWORD" | base64 -w0)

oc get secret vsphere-creds -o yaml -n kube-system > creds_backup.yaml
oc get cm cloud-provider-config -o yaml -n openshift-config > cloud-provider-config_backup.yaml
cp creds_backup.yaml vsphere-creds.yaml
cp cloud-provider-config_backup.yaml cloud-provider-config.yaml

sed -i "s/vcenterplaceholder.password:.*/${SERVER}.password: ${PASSWORD}/g" vsphere-creds.yaml
sed -i "s/vcenterplaceholder.username:.*/${SERVER}.username: ${USERNAME}/g" vsphere-creds.yaml
cat vsphere-creds.yaml
sleep 5s
oc replace -f vsphere-creds.yaml

#oc patch kubecontrollermanager cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge


# Update the YAML configuration file
sed -i "s#server=.*#server=$SERVER#" cloud-provider-config.yaml
sed -i "s#datacenter=.*#datacenter=$DATACENTER#" cloud-provider-config.yaml
sed -i "s#default-datastore=.*#default-datastore=$DEFAULT_DATASTORE#" cloud-provider-config.yaml
sed -i "s#folder=.*#folder=$FOLDER_NAME#" cloud-provider-config.yaml
sed -i "s/datacenters =.*/datacenters =  ${DATACENTER}/g" cloud-provider-config.yaml
sed -i "s/vcenterplaceholder/${SERVER}/g" cloud-provider-config.yaml
cat cloud-provider-config.yaml
sleep 15s
oc apply -f cloud-provider-config.yaml
oc patch kubecontrollermanager cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

#oc patch storageclass thin -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
#oc patch storageclass thin-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'