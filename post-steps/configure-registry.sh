#!/bin/bash

# Put the registry into a "Managed" state
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'

# Switch to the openshift-image-registry project
oc project openshift-image-registry

# Check if a registry pod is running
oc get pods

# Patch the registry config to have only one replica
oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'

# Create a Persistent Volume Claim
cat <<EOF | oc create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-storage 
spec:
  accessModes:
  - ReadWriteOnce 
  resources:
    requests:
      storage: 100Gi
EOF

# Edit the configuration of the imageregistry operator to use the PVC
oc patch config.imageregistry.operator.openshift.io cluster --type=merge \
    --patch '{"spec":{"storage":{"pvc":{"claim":""}}}}'

oc get config.imageregistry.operator.openshift.io cluster 
# Confirm that the registry pod is running
oc get pods -n openshift-image-registry | grep registry
