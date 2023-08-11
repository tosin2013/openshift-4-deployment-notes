# Import GKE cluster onto ACM

### Get pull secret from the link  below
https://cloud.redhat.com/openshift/install/pull-secret


### You can also get your pull secret from your cluster using the command below
```
DOCKER_CONFIG_JSON=`oc extract secret/pull-secret -n openshift-config --to=-`
oc create secret generic open-cluster-management-image-pull-credentials \
    -n open-cluster-management \
    --from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" \
    --type=kubernetes.io/dockerconfigjson
```

### Add pull secret to multiclusterhub operator
```
$ oc edit MultiClusterHub multiclusterhub -n open-cluster-management
spec:
  availabilityConfig: High
  hive:
    backup:
      velero: {}
    failedProvisionConfig: {}
  imagePullSecret: open-cluster-management-image-pull-credentials
  ingress:
    sslCiphers:
    - ECDHE-ECDSA-AES256-GCM-SHA384
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-ECDSA-CHACHA20-POLY1305
    - ECDHE-RSA-CHACHA20-POLY1305
    - ECDHE-ECDSA-AES128-GCM-SHA256
    - ECDHE-RSA-AES128-GCM-SHA256
  overrides: {}
  separateCertificateManagement: false
```

### Deploy Rancher on RHEL 9.2 
```
sudo systemctl disable nm-cloud-setup.service
sudo dnf update -y
sudo update-crypto-policies --set LEGACY
curl -sfL https://get.k3s.io/ | sh -s - --write-kubeconfig-mode 644
sudo sed -i '/ExecStartPre=/d' /etc/systemd/system/k3s.service
k3s --version
sudo systemctl status k3s
```


### Verify pull secret is configured on operator
```
$  kubectl get MultiClusterHub multiclusterhub -oyaml  -n open-cluster-management | grep -E "imagePullSecret:.*[a-z]{4}" 
  imagePullSecret: open-cluster-management-image-pull-credentials
```

### import GKE cluster


### Validate cluster has been imported
```
$ kubectl get pods -n open-cluster-management-agent
NAME                                             READY   STATUS    RESTARTS   AGE
klusterlet-75d64c754-w7x6q                       1/1     Running   0          37m
klusterlet-registration-agent-7b66b7fcf5-4zxt5   1/1     Running   0          37m
klusterlet-registration-agent-7b66b7fcf5-545lj   1/1     Running   0          37m
klusterlet-registration-agent-7b66b7fcf5-85spk   1/1     Running   0          37m
klusterlet-work-agent-5f999c7c4-4przc            1/1     Running   0          37m
klusterlet-work-agent-5f999c7c4-9kjl7            1/1     Running   0          37m
klusterlet-work-agent-5f999c7c4-kj7f9            1/1     Running   0          37m
```

