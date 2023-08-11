# Configure ACM with on Infra nodes

Latest documentation: https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.8/html/install/installing#tolerations

Configure Infra nodes  
```
$ 
$ oc patch ingresscontroller default -n openshift-ingress-operator --type merge -p '
{
  "spec": {
    "nodePlacement": {
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
}'

$ oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"replicas": 3}}' --type=merge
```

Deploy ACM with tolerations
```
$ oc create -f https://github.com/tosin2013/sno-quickstarts/gitops/cluster-config/rhacm-operator/base
$ cat >deployacm.yaml<<EOF
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: open-cluster-management
spec:
  tolerations:
  - key: node-role.kubernetes.io/infra
    effect: NoSchedule
    operator: Exists
EOF
$ oc create -f deployacm.yaml
```
