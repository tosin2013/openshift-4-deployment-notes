#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <vCenter URL> "
    exit 1
fi

wait_for_condition_message() {
  local desired_message="$1"

  while true; do
    local condition_message=$(oc get serviceexport zookeeper-east-0-internal -o jsonpath='{.status}' -n east | jq -r '.conditions[].message')

    if [[ $condition_message == "$desired_message" ]]; then
      echo "Condition message found: $condition_message"
      break
    else
      echo "Condition message is not yet '$desired_message'. Retrying in 5 seconds..."
      delete_matching_pod "submariner-operator"
      sleep 5
      local desired_message=$(oc get serviceexport zookeeper-east-0-internal -o jsonpath='{.status}' -n east | jq -r '.conditions[].message')
    fi
  done
}

OPENSHIFT_VERSION="4.13" # Versions 4.11, 4.12, and 4.13 are supported
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
    curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/vmware/machineset.yml
    cp machineset.yml machineset-useme.yml
fi

export KUBECONFIG=/home/$USER/cluster_${GUID}/auth/kubeconfig

COMPUTER_NAME=$(oc get nodes | grep  master-0 | awk '{print $1}')
MACHINE_CONFIG=$(echo "${COMPUTER_NAME}" | sed -E 's/-master-0$//')
sed -i "s/ds8m4-zqd8z/$MACHINE_CONFIG/g" machineset-useme.yml
sed -i "s/ds8m4/$GUID/g" machineset-useme.yml
sed -i "s/portal.example.com/${VCENTER_URL}/g" machineset-useme.yml
if [ $OPENSHIFT_VERSION == "4.13" ];
then
    sed -i "s|ds8m4-zqd8z-rhcos|${MACHINE_CONFIG}-rhcos-region1-zone1|g" machineset-useme.yml
fi
cat machineset-useme.yml
echo "Press Enter to continue, or wait 15 seconds for the script to continue automatically"
read -t 15 -p "Press Enter to continue, or wait 15 seconds for the script to continue automatically"
oc apply -f machineset-useme.yml
rm  machineset-useme.yml

# Wait until the READY count of the MachineSet is equal to 3
USE_NAME=$(oc get nodes | grep  master-0 | awk '{print $1}' | sed 's/-master-0//g')
while true; do
  ready_count=$(oc get machineset ${USE_NAME}-infra -n openshift-machine-api -o=jsonpath='{.status.readyReplicas}')
  if [[ $ready_count -eq 3 ]]; then
    echo "All machines are ready"
    break
  else
    echo "Waiting for all machines to be ready"
    sleep 10
  fi
done

git clone https://github.com/tosin2013/sno-quickstarts.git
cd sno-quickstarts/gitops/cluster-config
oc create -k openshift-local-storage/operator/overlays/stable-${OPENSHIFT_VERSION}/
sleep 120s
# Define the new values
new_values=($(oc get nodes --no-headers -o custom-columns='NAME:.metadata.name' | grep infra))
echo "New values: ${new_values[@]}"

# Loop through and replace "worker-0", "worker-1", and "worker-2" if the corresponding value exists
for i in {0..2}; do
  if [[ $i -lt ${#new_values[@]} ]]; then
    value=${new_values[i]}
    oc label node $value node-role.kubernetes.io/infra=""
    sed "s/worker-$i.example.com/${value}/g" openshift-local-storage/instance/overlays/bare-metal/kustomization.yaml -i 
  fi
done

oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"replicas": 3}}' --type=merge
oc patch ingresscontroller default -n openshift-ingress-operator --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/nodePlacement",
    "value": {
      "nodeSelector": {
        "matchLabels": {
          "node-role.kubernetes.io/infra": ""
        }
      },
      "tolerations": [
        {
          "effect": "NoSchedule",
          "key": "node-role.kubernetes.io/infra",
          "value": "reserved"
        },
        {
          "effect": "NoExecute",
          "key": "node-role.kubernetes.io/infra",
          "value": "reserved"
        }
      ]
    }
  }
]'

cat openshift-local-storage/instance/overlays/bare-metal/kustomization.yaml

for i in "${new_values[@]}"
do
	echo "$i"
    oc label node $i cluster.ocs.openshift.io/openshift-storage=""
done
oc create -k openshift-local-storage/instance/overlays/bare-metal --dry-run=client -o yaml 
oc create -k openshift-local-storage/instance/overlays/bare-metal
sleep 120s

oc create -k openshift-data-foundation-operator/operator/overlays/stable-${OPENSHIFT_VERSION}  --dry-run=client -o yaml 
oc create -k openshift-data-foundation-operator/operator/overlays/stable-${OPENSHIFT_VERSION}
sleep 120s


oc create -k openshift-data-foundation-operator/instance/overlays/bare-metal --dry-run=client -o yaml 
oc create -k openshift-data-foundation-operator/instance/overlays/bare-metal

oc patch storageclass thin -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
oc patch storageclass ocs-storagecluster-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


#curl -OL https://raw.githubusercontent.com/tosin2013/openshift-demos/master/quick-scripts/deploy-gitea.sh
#chmod +x deploy-gitea.sh
#./deploy-gitea.sh