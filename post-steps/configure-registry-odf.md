# Configure with Internal Image Registry to Use Red Hat OpenShift Data Foundation


**Login to OpenShift**
```
$ oc login https://api.ocp4.example.com:6443
```

**Create noobaa registry for storage**
```
$ cat >odf-registry.yaml<<YAML
---
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: noobaa-registry
  namespace: openshift-image-registry 
  finalizers:
    - objectbucket.io/finalizer
  labels:
    app: noobaa
    bucket-provisioner: openshift-storage.noobaa.io-obc
    noobaa-domain: openshift-storage.noobaa.io
spec:
  additionalConfig:
    bucketclass: noobaa-default-bucket-class
  objectBucketName: noobaa-registry-bucket
  storageClassName: openshift-storage.noobaa.io
  bucketName: noobaa-registry-bucket
YAML

$ oc create -f odf-registry.yaml
```

**Check status**
```
$ oc get -n openshift-image-registry objectbucketclaim/noobaa-registry
```

**Extract Secret** 
```
$ oc extract secret/noobaa-registry -n openshift-image-registry
```

**Create Secret for registry** 
```
$ oc create secret generic image-registry-private-configuration-user --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY="$(cat AWS_ACCESS_KEY_ID)" --from-literal=REGISTRY_STORAGE_S3_SECRETKEY="$(cat AWS_SECRET_ACCESS_KEY)" -n openshift-image-registry
```

**Create Secure Image registry** 
```
$ BUCKET_NAME=$(oc get -n openshift-image-registry objectbucketclaim/noobaa-registry -o jsonpath='{.spec.bucketName}{"\n"}')
$ S3_ACCOUNT=https://$(oc get route/s3 -n openshift-storage -o jsonpath='{.spec.host}{"\n"}') 
$ cat >patch-imageregistry.yaml<<YAML
---
apiVersion: imageregistry.operator.openshift.io/v1
kind: Config
metadata:
  name: cluster
spec:
  storage:
    managementState: Managed 
    pvc: null
    s3:
      bucket: ${BUCKET_NAME}
      region: us-east-1
      regionEndpoint: ${S3_ACCOUNT}
YAML
$ oc patch configs.imageregistry/cluster --type=merge --patch-file=patch-imageregistry.yaml
```

**Create Insecure Image registry** 
```
$ BUCKET_NAME=$(oc get -n openshift-image-registry objectbucketclaim/noobaa-registry -o jsonpath='{.spec.bucketName}{"\n"}')
$ S3_ACCOUNT=http://s3.openshift-storage.svc
$ cat >patch-imageregistry.yaml<<YAML
---
apiVersion: imageregistry.operator.openshift.io/v1
kind: Config
metadata:
  name: cluster
spec:
  storage:
    managementState: Managed 
    pvc: null
    s3:
      bucket: ${BUCKET_NAME}
      region: us-east-1
      regionEndpoint: ${S3_ACCOUNT}
YAML
$ oc patch configs.imageregistry/cluster --type=merge --patch-file=patch-imageregistry.yaml
```

**Set Registry managementState to Managed**
```
$ oc edit configs.imageregistry/cluster 
```

**Verify managementState**
```
$ oc get configs.imageregistry/cluster  -oyaml | grep managementState
```

**Verify status**
```
$ oc get configs.imageregistry/cluster -o jsonpath='{.spec.storage}' | jq .
```

**Verify pod exists**
```
$ watch oc get pods -n openshift-image-registry -l docker-registry=default
```

**Change imageregistry.operator.openshift.io/v1 to managed**
```
$ oc edit  configs.imageregistry/cluster
```
