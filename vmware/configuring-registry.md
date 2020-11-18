# Configuring Registiry for image-registry-storage 

## Create VMDK on vmware
**SSH into ESXi host**
```
ssh root@<insert IP address of ESXi host here>
```

**List the storage endpoints**
```
esxcli storage filesystem list
Mount Point                                        Volume Name  UUID                                 Mounted  Type            Size          Free
-------------------------------------------------  -----------  -----------------------------------  -------  ------  ------------  ------------
/vmfs/volumes/5fa1c2af-46adb800-eb60-24b6fdff0ec2  datastore1   5fa1c2af-46adb800-eb60-24b6fdff0ec2     true  VMFS-6  471909531648  469474738176
/vmfs/volumes/5fa1c440-84d411d8-96e3-24b6fdff0ec2  datastore2   5fa1c440-84d411d8-96e3-24b6fdff0ec2     true  VMFS-6  999922073600  505899122688
/vmfs/volumes/5fa1c452-b599bcc0-4417-24b6fdff0ec2  datastore3   5fa1c452-b599bcc0-4417-24b6fdff0ec2     true  VMFS-6  999922073600   78464942080
/vmfs/volumes/28337976-bc23830c-13dc-9198e73061ba               28337976-bc23830c-13dc-9198e73061ba     true  vfat       261853184     261849088
/vmfs/volumes/5fa1c280-aa491526-b517-24b6fdff0ec2               5fa1c280-aa491526-b517-24b6fdff0ec2     true  vfat       299712512     116998144
/vmfs/volumes/7785f478-65d6543f-9b0c-aad3b0d1ca15               7785f478-65d6543f-9b0c-aad3b0d1ca15     true  vfat       261853184     108044288
/vmfs/volumes/5fa1c2af-768d249c-e007-24b6fdff0ec2               5fa1c2af-768d249c-e007-24b6fdff0ec2     true  vfat      4293591040    4261216256

```

**cd into volume and create a volumes folder**
```
cd <copy Mount Point from above here>
```

**Create volumes directory and cd into volumes**
```
mkdir volumes
cd volumes
```
**Create virtual disk for registry**
```
vmkfstools --createvirtualdisk 100G --diskformat zeroedthick Registry.vmdk
```

## Create registry on OpenShift

**set the image registry storage as a block storage type, patch the registry so that it uses the Recreate rollout strategy and runs with only 1 replica:**
```
$ oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
```

**create PV**
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001 
spec:
  capacity:
    storage: 100Gi 
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: thin
  vsphereVolume: 
    volumePath: "[datastore2] volumes/Registry" 
    fsType: ext4 
```

Create PVC
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

Edit the image Registry settings
```
oc edit configs.imageregistry.operator.openshift.io
```

Change managementState to Managed
```
spec:
  logLevel: Normal
  managementState: Managed
```

Update storage
```
storage:
  pvc:
    claim: 
```

**Link:**  
[Configuring block registry storage for VMware vSphere](https://docs.openshift.com/container-platform/4.6/registry/configuring_registry_storage/configuring-registry-storage-vsphere.html#installation-registry-storage-block-recreate-rollout_configuring-registry-storage-vsphere)