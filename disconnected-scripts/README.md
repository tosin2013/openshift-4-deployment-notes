# Script to configure disconnected environments

## Requirements
* Configure FQDN for hostname 
```
sudo hostnamectl set-hostname registry.example.com
```
* Ansible 
```
sudo dnf install ansible-core
```
* Podman
```
sudo dnf module install -y container-tools
```
* Set up for rootless containers
```
# sudo yum install slirp4netns podman -y
# sudo tee -a /etc/sysctl.d/userns.conf > /dev/null <<EOT
user.max_user_namespaces=28633
EOT
# sudo sysctl -p /etc/sysctl.d/userns.conf
```
* jq 
```
sudo dnf install jq -y
```
* libvirt for mirror-ocp-full.sh 
```
sudo dnf install libvirt -y
```
## Quay Mirror Registry Script
> https://github.com/quay/mirror-registry/releases

**Download mirror registry**
```
VERSION=1.1.0 # Testing
VERSION=v1.3.10  #Stable
curl -OL https://github.com/quay/mirror-registry/releases/download/${VERSION}/mirror-registry-offline.tar.gz
tar -zxvf mirror-registry-offline.tar.gz
```
**install mirror registry**
```
mkdir -p /registry/
sudo ./mirror-registry install \
  --quayHostname $(hostname) \
  --quayRoot /registry/
```

**Configure firewall**

```
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
```

**Set semanage ports for selinux**
```
sudo semanage port  -a 8443 -t http_port_t -p tcp
sudo semanage port  -l  | grep -w http_port_t
```


**To uninstall mirror registry**
```
sudo ./mirror-registry uninstall -v
```


# On jumpbox or bastion host

## Get OpenShift Pull Secret and save it to `~/pull_secret.json`
> [Install OpenShift on Bare Metal](https://console.redhat.com/openshift/install/metal/installer-provisioned)

```bash
vim ~/pull_secret.json
```

**To mirror an OpenShift release to Quay**
* Change registry url to your registry url in `mirror-ocp-release.sh`
```
export REGISTRY_URL=$(hostname)
```

* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-release.sh
```

* run the mirror-ocp-release.sh script
```
./mirror-ocp-release.sh
```

**To mirror an OpenShift release and host OpenShift Binaries for UBI deployments**
* Change registry url to your registry url in `mirror-ocp-full.sh`
```
export REGISTRY_URL=$(hostname)
```
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-full.sh
```

* run the ./mirror-ocp-full.sh
```
./mirror-ocp-full.sh
```

**To mirror an OpenShift release and host OpenShift Binaries for assisted installer deployments**
* Change registry url to your registry url in `mirror-ocp-full.sh`
```
export REGISTRY_URL=$(hostname)
```
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-full.sh
```
* run the get-ai-svc-version.sh
> create `vim $HOME/rh-api-offline-token` is the token generated from this page: https://access.redhat.com/management/api
```
./get-ai-svc-version.sh
```

* run the ./mirror-ocp-full.sh
```
./mirror-ocp-full.sh
```

**Location of Quay Certificate after deployment**
```
cat /registry/quay-rootCA/rootCA.pem
```

## add pull secert to install-config.yaml
```
$ echo "pullSecret: '$(jq -c . merged-pull-secret.json)'" >> install-config.yaml 
```

## Add certificate to our trust bundles in our install-config.yaml 
```
$ vim ~/domain.crt
$ sed -i -e 's/^/  /' ~/domain.crt
$ echo "additionalTrustBundle: |" >> install-config.yaml
$ cat ~/domain.crt >> install-config.yaml
$ vim install-config.yaml
```

Links:
* [Mirroring OpenShift Registries: The Easy Way](https://cloud.redhat.com/blog/mirroring-openshift-registries-the-easy-way)
