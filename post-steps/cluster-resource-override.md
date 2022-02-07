# Configure Cluster Override

## Install the Cluster Resource Override Operator
```
$ ./post-steps/configure-cluster-override.sh
```
**Change to the `clusterresourceoverride-operator` namespace.**
```
$ oc project clusterresourceoverride-operator
```

**Configure cluster-level overcommit**
```
cat >configure-override.yml<<YAML
apiVersion: operator.autoscaling.openshift.io/v1
kind: ClusterResourceOverride
metadata:
    name: cluster 
spec:
  podResourceOverride:
    spec:
      memoryRequestToLimitPercent: 50 
      cpuRequestToLimitPercent: 25 
      limitCPUToMemoryPercent: 200 
YAML
```

**Apply the override**
```
oc apply -f configure-override.yml
```

