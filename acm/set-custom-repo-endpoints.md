# Set Custom Image endpoints for ACM Deployments

Below show the custom registry endpoint options that can be used against your cluster. You may want to use this function you are using a disconnected registry. 

# Set custom images in ACM 

Github References 
* https://github.com/open-cluster-management/multiclusterhub-operator/tree/main/docs/examples
* https://github.com/open-cluster-management/multiclusterhub-operator/blob/main/docs/configuration.md

There are two ways to configure custom images on ACM 

## Option 1: update all images at once 
**Pull down one image json**
```
curl -OL https://raw.githubusercontent.com/open-cluster-management/multiclusterhub-operator/v2.2.0-2021-02-18-23-41-24/docs/examples/manifest-oneimage.json
```

**Create config map**
```
kubectl create configmap bulkimage --from-file=manifest-oneimage.json -n open-cluster-management
```

**Override multiclusterhub image overrides**
```
kubectl annotate mch multiclusterhub --overwrite mch-imageOverridesCM=bulkimage -n open-cluster-management
```

## Option 2: Update images individually
> This Option is useful if you are in an enviornment with a disconnected registry that uses replication. 

**Optional: Add pull secret to multiclusterhub operator**
```
$  kubectl get MultiClusterHub multiclusterhub -oyaml  -n open-cluster-management | grep -E "imagePullSecret:.*[a-z]{4}" 
  imagePullSecret: quay
```

**Create image override json file**
> Override file example
```
cat >custom-override.json<<EOF
[
  {
    "image-name": "ose-oauth-proxy",
    "image-remote": "quay.io/open-cluster-management",
    "image-digest": "sha256:3948de88df41ba184c0541146997dbfbc705e2a9489f6433fb8da2858eecd041",
    "image-key": "oauth_proxy"
  }
]
EOF
```

**Create config map**
```
kubectl create configmap ose-oauth-proxy --from-file=custom-override.json -n open-cluster-management
```

**Override multiclusterhub image overrides**
```
kubectl annotate mch multiclusterhub --overwrite mch-imageOverridesCM=ose-oauth-proxy -n open-cluster-management
```

**Patch imageRepository annoation**
```
kubectl annotate mch multiclusterhub --overwrite mch-imageRepository=registry.redhat.io/rhacm2 -n open-cluster-management
```
**Patch the imageOverridesCM with the config map**
```
kubectl annotate mch multiclusterhub --overwrite mch-imageOverridesCM=ose-oauth-proxy  -n open-cluster-management
```

**The result should look like the view below**
```
$ kubectl get MultiClusterHub multiclusterhub -oyaml  -n open-cluster-management | grep -A4 "MultiClusterHub" 
kind: MultiClusterHub
metadata:
  annotations:
    mch-imageOverridesCM: ose-oauth-proxy
    mch-imageRepository: registry.redhat.io/rhacm2
```







