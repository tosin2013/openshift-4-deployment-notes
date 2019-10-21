# Performing OpenShift 4 installation

**Prerequisites**
* The infrastructure has been created
* The installation program and Ignition config files are avialable for the cluster. 

NOTE: ocp4 is installation directory in this example

**Monitor the boot strap process**  
```
$ openshift-install --dir=ocp4 wait-for bootstrap-complete --log-level debug
```

**Login to the cluster**  
Export the kubeadmin credentials:  
```
$ export KUBECONFIG=<installation_directory>/auth/kubeconfig 
```

Check logged on user  
```
$ oc whoami 
```

**Check for Pending CSRs**  
[Approving the CSRs for your machines](https://docs.openshift.com/container-platform/4.2/installing/installing_bare_metal/installing-bare-metal.html?extIdCarryOver=true&sc_cid=701f2000001Css5AAC#installation-approve-csrs_installing-bare-metal)


**Watch the cluster components come online**
```
$ watch -n5 oc get clusteroperators

NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.2.0     True        False         False	  36h
cloud-credential                           4.2.0     True        False         False	  36h
cluster-autoscaler                         4.2.0     True        False         False	  36h
console                                    4.2.0     True        False         False	  36h
dns                                        4.2.0     True        False         False	  36h
image-registry                             4.2.0     True        False         False	  36h
ingress                                    4.2.0     True        False         False	  36h
insights                                   4.2.0     True        False         False	  36h
kube-apiserver                             4.2.0     True        False         False	  36h
kube-controller-manager                    4.2.0     True        False         False	  36h
kube-scheduler                             4.2.0     True        False         False	  36h
machine-api                                4.2.0     True        False         False	  36h
machine-config                             4.2.0     True        False         False	  36h
marketplace                                4.2.0     True        False         False	  36h
monitoring                                 4.2.0     True        False         False	  36h
network                                    4.2.0     True        False         False	  36h
node-tuning                                4.2.0     True        False         False	  36h
openshift-apiserver                        4.2.0     True        False         False	  36h
openshift-controller-manager               4.2.0     True        False         False	  36h
openshift-samples                          4.2.0     True        False         False	  36h
operator-lifecycle-manager                 4.2.0     True        False         False	  36h
operator-lifecycle-manager-catalog         4.2.0     True        False         False	  36h
operator-lifecycle-manager-packageserver   4.2.0     True        False         False	  21h
service-ca                                 4.2.0     True        False         False	  36h
service-catalog-apiserver                  4.2.0     True        False         False	  36h
service-catalog-controller-manager         4.2.0     True        False         False	  36h
storage                                    4.2.0     True        False         False	  36h

```

**Configure registry** 
[Image registry storage configuration](https://docs.openshift.com/container-platform/4.2/installing/installing_bare_metal/installing-bare-metal.html?extIdCarryOver=true&sc_cid=701f2000001Css5AAC#installation-registry-storage-config_installing-bare-metal)

**Confirm that all the cluster components are online:**
```
$ watch -n5 oc get clusteroperators

NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.2.0     True        False         False	  36h
cloud-credential                           4.2.0     True        False         False	  36h
cluster-autoscaler                         4.2.0     True        False         False	  36h
console                                    4.2.0     True        False         False	  36h
dns                                        4.2.0     True        False         False	  36h
image-registry                             4.2.0     True        False         False	  36h
ingress                                    4.2.0     True        False         False	  36h
insights                                   4.2.0     True        False         False	  36h
kube-apiserver                             4.2.0     True        False         False	  36h
kube-controller-manager                    4.2.0     True        False         False	  36h
kube-scheduler                             4.2.0     True        False         False	  36h
machine-api                                4.2.0     True        False         False	  36h
machine-config                             4.2.0     True        False         False	  36h
marketplace                                4.2.0     True        False         False	  36h
monitoring                                 4.2.0     True        False         False	  36h
network                                    4.2.0     True        False         False	  36h
node-tuning                                4.2.0     True        False         False	  36h
openshift-apiserver                        4.2.0     True        False         False	  36h
openshift-controller-manager               4.2.0     True        False         False	  36h
openshift-samples                          4.2.0     True        False         False	  36h
operator-lifecycle-manager                 4.2.0     True        False         False	  36h
operator-lifecycle-manager-catalog         4.2.0     True        False         False	  36h
operator-lifecycle-manager-packageserver   4.2.0     True        False         False	  21h
service-ca                                 4.2.0     True        False         False	  36h
service-catalog-apiserver                  4.2.0     True        False         False	  36h
service-catalog-controller-manager         4.2.0     True        False         False	  36h
storage                                    4.2.0     True        False         False	  36h

```

**Monitor for cluster completion:**
```
$ openshift-install --dir=ocp4 wait-for install-complete --log-level debug
```

**Confirm that the Kubernetes API server is communicating with the Pods.**
```
$ oc get pods --all-namespaces
```