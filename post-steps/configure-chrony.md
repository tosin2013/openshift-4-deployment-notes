# Configure Chrony

* [Configuring chrony time service](https://docs.openshift.com/container-platform/4.10/installing/install_config/installing-customizing.html#installation-special-config-chrony_installing-customizing)

## Install Butane 

```
curl https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane --output butane
chmod +x butane
mv butane /usr/local/bin
```

## Create a Butane config file 
> control plane node 
```
cat >99-master-chrony.bu<<EOF
variant: openshift
version: 4.10.0
metadata:
  name: 99-master-chrony 
  labels:
    machineconfiguration.openshift.io/role: master 
storage:
  files:
  - path: /etc/chrony.conf
    mode: 0644 
    overwrite: true
    contents:
      inline: |
        pool 0.rhel.pool.ntp.org iburst 
        driftfile /var/lib/chrony/drift
        makestep 1.0 3
        rtcsync
        logdir /var/log/chrony
EOF

butane 99-master-chrony.bu -o 99-master-chrony.yaml

oc apply -f ./99-master-chrony.yaml

watch oc get nodes 
```

>  worker node 
```
cat >99-worker-chrony.bu<<EOF
variant: openshift
version: 4.10.0
metadata:
  name: 99-worker-chrony 
  labels:
    machineconfiguration.openshift.io/role: worker 
storage:
  files:
  - path: /etc/chrony.conf
    mode: 0644 
    overwrite: true
    contents:
      inline: |
        pool 0.rhel.pool.ntp.org iburst 
        driftfile /var/lib/chrony/drift
        makestep 1.0 3
        rtcsync
        logdir /var/log/chrony
EOF

butane 99-worker-chrony.bu -o 99-worker-chrony.yaml

oc apply -f ./99-worker-chrony.yaml

watch oc get nodes 
```