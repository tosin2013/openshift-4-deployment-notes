# Configure Ansible tower on OpenShift

## Requirements
* OpenShift Deployment
* oc cli

## Automated Steps
## Manual Steps
* ssh into bastion host
* Download `ansible-tower-openshift-setup-latest.tar.gz`
```
$ curl -OL https://releases.ansible.com/ansible-tower/setup_openshift/ansible-tower-openshift-setup-latest.tar.gz
```
* Untar the contents of the Setup Script
```
tar -xzf ansible-tower-openshift-setup-latest.tar.gz
```

* Modify the openshift_auth.yml file on line `-name: Authenticate with OpenShift via user and password`
```
Change too
--insecure-skip-tls-verify={{ openshift_skip_tls_verify | default(true) |   bool }}
```
* login to OpenShift cluster 
```
oc login https://api.ocp4.example.com:6443 -u=admin  -p=p@ssw@rD
```

* Create `PersistentVolumeClaim` for tower
```
$ cat >postgres-nfs-pvc.yml<<EOF
 kind: PersistentVolumeClaim
 apiVersion: v1
 metadata:
  name: postgresql
 spec:
  accessModes:
   - ReadWriteOnce
  resources:
   requests:
    storage: 20Gi
EOF 
$ oc create -f postgres-nfs-pvc.yml
```

* Run setup 
```
./setup_openshift.sh -e openshift_host=https://YOUR-OCP-CLUSTER-API-API-URL -e openshift_project=tower -e openshift_user=YOUR-OCP-ADMIN-USERNAME -e openshift_password=YOUR-OCP-PASSWORD -e admin_password=r3dh4t1! -e secret_key=mysecret -e pg_username=admin -e pg_password=r3dh4t1! -e rabbitmq_password=r3dh4t1! -e rabbitmq_erlang_cookie=rabbiterlangpwd -e openshift_pg_pvc_name=postgresql
```