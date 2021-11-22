# Steps to add worker node 
The following  will explain how to ad worker nodes to existing baremetal assisted installer deployment.


## Steps 
> Testing in progress

1. Ensure `cluster-vars.sh` have the correct settings if it does not rerun the `bootstrap.sh` script using the steps [here](README.md).
2. run the `add-nodes-bootstrap.sh` script
3. Boot worker node with created iso 
4. Run the `start-node-install.sh` script 



* Wait for the new worker to reboot and check pending CSRs
```
 oc get csr|grep Pending
```

* Approve all CSR's
```
 for csr in $(oc -n openshift-machine-api get csr | awk '/Pending/ {print $1}'); do oc adm certificate approve $csr;done
```

* After a few minutes the nodes should be ready


## To-Do 
* add script for waiting for node CSRs
*