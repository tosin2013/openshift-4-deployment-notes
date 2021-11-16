# Assisted Installer Scripts

## Assisted Installer Steps for bare metal with static ips
1. Get offline token and save it to offline-token.txt  
[Red Hat API Tokens](https://access.redhat.com/management/api)
```
vim ~/offline-token.txt
```

2. Create OpenShift pull secret  
[Install OpenShift on Bare Metal](https://console.redhat.com/openshift/install/metal/installer-provisioned)
```
vim ~/pull-secret.txt
```
3. Patch cluster with custom settings
```
$ vim ~/patch-deployment.sh
$ ./patch-deployment.sh
```

4. Generate nodes with static ips for environment
```
$ vim ~/patch-deployment.sh
$ ./patch-deployment.sh
``` 
5. Generate ISO for cluster
```
$ vim ~/create-custom-iso.sh
$ ./create-custom-iso.sh
```

6. Boot Each machine with custom ISO

## Links: 
* https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive
* https://github.com/kenmoini/ocp4-ai-svc-libvirt
* https://cloudcult.dev/creating-openshift-clusters-with-the-assisted-service-api/