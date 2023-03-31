#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <vCenter URL> "
    exit 1
fi

VCENTER_URL=$1
# Check that all arguments were provided
if [ ! -f /home/$USER/cluster_${GUID}/auth/kubeconfig ];
then
    echo "Kubeconfig file not found"
    exit 1
fi

if [ -f machineset.yml ];
then
    echo "machineset.yml file already exists"
    cp machineset.yml machineset-useme.yml
else
    curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/machineset.yml
    cp machineset.yml machineset-useme.yml
fi

export KUBECONFIG=/home/$USER/cluster_${GUID}/auth/kubeconfig

COMPUTER_NAME=$(oc get nodes | grep  master-0 | awk '{print $1}')
echo "${COMPUTER_NAME}" | sed -E 's/-master-0$//'
sed  's/ds8m4-zqd8z/NEW_VALUE/g' machineset-useme.yml
sed  "s/ds8m4/$GUID/g" machineset-useme.yml
sed "s/portal.example.com/${VCENTER_URL}/g" machineset-useme.yml
cat machineset-useme.yml | less
oc apply -f machineset-useme.yml
rm  machineset-useme.yml