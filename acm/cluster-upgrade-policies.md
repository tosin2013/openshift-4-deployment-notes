# ACM cluster Policy Update

[policy-upgrade-openshift-cluster](https://github.com/open-cluster-management/policy-collection/blob/main/community/CM-Configuration-Management/policy-upgrade-openshift-cluster.yaml)

Login to target cluster 


On target cluster get the current cluster version
```
oc get clusterversion -o yaml| grep channel
          f:channel: {}
            f:channels: {}
    channel: stable-4.6
      channels:
```

On ACM Cluster create namespace for policy updates
```
oc create -f https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/acm/create-update-policy-ns.yaml
```

On ACM Cluster Create upgrade policy
```
 oc create -f https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/acm/cluster-update-policy.yaml
```

![](https://i.imgur.com/V2VrpGA.png)
![](https://i.imgur.com/vkOk7jQ.png)
![](https://i.imgur.com/GybGQp2.png)
![](https://i.imgur.com/EppTwsB.png)
