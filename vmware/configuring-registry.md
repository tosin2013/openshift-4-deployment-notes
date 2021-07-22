# Configuring the Registry for Perisistent Storage 

## Manage the registry on OpenShift

Put the registry into a "Managed" state:

```
$ oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
```
Make sure we are in the right project (namespace):
```
$ oc project openshift-image-registry
```

Check to see if a registry pod is running:
```
oc get pods
```

You should see something like the following: The Operator, two image-pruner pods (nbot running), and one node-ca pod per workers+controlplane nodes (but no registry pods):

```
NAME                                               READY   STATUS      RESTARTS   AGE
cluster-image-registry-operator-64f5467494-qpz4q   1/1     Running     1          2d8h
image-pruner-1626825600-bxcwn                      0/1     Completed   0          44h
image-pruner-1626912000-tz65z                      0/1     Completed   0          20h
node-ca-57k6g                                      1/1     Running     0          2d8h
node-ca-bhz6s                                      1/1     Running     0          2d8h
node-ca-kph47                                      1/1     Running     0          2d8h
node-ca-r8dnt                                      1/1     Running     0          2d8h
node-ca-v5qdz                                      1/1     Running     0          2d8h
node-ca-zn992                                      1/1     Running     0          2d8h
```
Now we patch the registry config so that only one replica is running. This is important as we will be using Read Write Once (RW()) Block storage:

```
 $ oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
```

** Create a Persistent Volume Claim **

The name (image-registry-storage) and size (100Gi) are important to have exactly correct.

We will put the following into a file called ```pvc.yaml```

```
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
```
Now create the claim:

```
$ oc create -f  pvc.yaml -n openshift-image-registry
```
This creates the pvc, and binds it to a thin provisioned backing store in our VMware folder.

At this point, we will edit the configuration of the imageregistry operator to make the claim:

```
$ oc edit config.imageregistry.operator.openshift.io
```

Our storage: configuration looks like this:

```
  storage: {}
```

Edit to look like this:

```
  storage:
    pvc:
      claim: 
```

Save the edit.

Upon inspection (re edit) you will see that this is what we have:

```
  storage:
    pvc:
      claim: image-registry-storage
```

image-registry-storage is automatically chosen by the operator as the pvc.

Lastly, to confirm all is well, let's see if the registry pod is running:

```
$ oc get pods -n openshift-image-registry | grep registry
```
will yield:

```
cluster-image-registry-operator-64f5467494-qpz4q   1/1     Running     1          2d8h
image-registry-65477c8b8-7cdxj                     1/1     Running     0          6m4s
```

Now we see a registry pod running along with the governing operator pod.

**Link:**  
[Configuring block registry storage for VMware vSphere](https://docs.openshift.com/container-platform/4.7/registry/configuring_registry_storage/configuring-registry-storage-vsphere.html#installation-registry-storage-block-recreate-rollout_configuring-registry-storage-vsphere)