#!/bin/bash 

cat >/tmp/cro-namespace.yaml<<YAML
---
apiVersion: v1
kind: Namespace
metadata:
  name: clusterresourceoverride-operator
YAML

cat >/tmp/cro-og.yaml<<YAML
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: clusterresourceoverride-operator
  namespace: clusterresourceoverride-operator
spec:
  targetNamespaces:
    - clusterresourceoverride-operator
YAML

cat >/tmp/cro-sub.yaml<<YAML
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: clusterresourceoverride
  namespace: clusterresourceoverride-operator
spec:
  channel: "4.9"
  name: clusterresourceoverride
  source: redhat-operators
  sourceNamespace: openshift-marketplace
YAML

oc create -f /tmp/cro-namespace.yaml
oc create -f /tmp/cro-og.yaml
oc create -f /tmp/cro-sub.yaml
