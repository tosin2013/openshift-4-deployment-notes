# Operator Lifecycle Manager on restricted networks


## Requirements 

**gRPCurl**
* https://github.com/fullstorydev/grpcurl/releases/
```
curl -OL https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz
tar -zxvf grpcurl_1.8.6_linux_x86_64.tar.gz
sudo mv grpcurl /usr/local/bin/
```


**opm**
https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/


Disable the sources for the default catalogs by adding disableAllDefaultSources: true to the OperatorHub object:

```
oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

***Authenticate with registry.redhat.io**
```
 podman login registry.redhat.io
```
***Authenticate to your internal registry**
```
INTERNAL_REGISTRY=quay.example.com:8443
podman  login ${INTERNAL_REGISTRY}  --tls-verify=false
```
**Run the source index image that you want to prune in a container.**
```
OPENSHIFT_VERSION=4.10
podman run -p50051:50051 -d -it registry.redhat.io/redhat/redhat-operator-index:v${OPENSHIFT_VERSION}
```

**Use the grpcurl command to get a list of the packages provided by the index:**
```
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out
```

**Select packages from market place**
```
cat packages.out | grep -E 'local-storage|odf'  | awk '{print $2}' | tr '"' ' '  | sed 's/ //g' | tee -a saved-packages.log
```

Run the following command to prune the source index of all but the specified packages:
```
$ export PORT=8443
$ export LOCAL_REGISTRY=${INTERNAL_REGISTRY}
# For Quay Registry 
$ export LOCAL_REPOSITORY=olm-mirror
# For Artifactory Example: jfrog
$ export LOCAL_REPOSITORY=olm-mirror/olm-mirror
$ opm index prune \
    -f registry.redhat.io/redhat/redhat-operator-index:v${OPENSHIFT_VERSION} \
    -p $(cat saved-packages.log | paste -d ',' -s) \
    -t ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/redhat-operator-index:v${OPENSHIFT_VERSION}
```

Run the following command to push the new index image to your target registry:
```
$ export TLS_VERIFY=false
$ podman login --authfile ~/merged-pull-secret.json \
  ${LOCAL_REGISTRY} \
  --tls-verify=${TLS_VERIFY} 
$ podman push ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/redhat-operator-index:v${OPENSHIFT_VERSION}
```

## Adding a catalog source to a cluster
**Create Catalog source for registry**
```
cat >catalogSource.yaml<<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-operator-catalog 
  namespace: openshift-marketplace 
spec:
  sourceType: grpc
  image: ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/redhat-operator-index:v${OPENSHIFT_VERSION} 
  displayName: Custom Operator Catalog
  publisher: Red Hat
  updateStrategy:
    registryPoll: 
      interval: 30m
EOF
```
                             
**Apply the changes**
```
oc apply -f catalogSource.yaml
```

**Check the status in OpenShift Marketplace**
```
$ oc get pods -n openshift-marketplace
NAME                                    READY   STATUS              RESTARTS   AGE
marketplace-operator-74657cd4bd-jqrpj   1/1     Running             0          5h59m
my-operator-catalog-gx4gg               0/1     ContainerCreating   0          4s
```
                             
