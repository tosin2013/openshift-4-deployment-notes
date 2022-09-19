#!/bin/bash 


git clone https://github.com/tosin2013/gitops-catalog.git
cd ~/gitops-catalog/
oc apply -k openshift-local-storage/operator/overlays/stable-4.10/
sleep 120s
oc apply -k openshift-local-storage/instance/overlays/bare-metal/
sleep 60s
oc apply -k openshift-data-foundation-operator/operator/overlays/stable-4.10/

kubectl patch storageclass thin -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass ocs-storagecluster-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'