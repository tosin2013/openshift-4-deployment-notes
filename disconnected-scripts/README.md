# Script to configure disconnected enviornments

## Requirements
* Configure FQDN for hostname 
```
sudo hostnamectl set-hostname registry.example.com
```
* Ansible 
```
sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
sudo dnf install ansible
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

### Download mirror registry
```
VERSION=1.0.0
curl -OL https://github.com/quay/mirror-registry/releases/download/${VERSION}/mirror-registry-offline.tar.gz
tar -zxvf mirror-registry-offline.tar.gz
```
### install mirror registry
```
mkdir -p /registry/
sudo ./mirror-registry install \
  --quayHostname $(hostname) \
  --quayRoot /registry/
```
### Configure firewall
```
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
```

### Set semanage ports for selinux
```
sudo semanage port  -a 8443 -t http_port_t -p tcp
sudo semanage port  -l  | grep -w http_port_t
```


### To uninstall mirror registry 
```
sudo ./mirror-registry uninstall -v
```

## TO-DO Generic Registry Creation Script
> Ad steps to use generic registry


# To mirror an OpenShift release to Quay
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-release.sh
```

* run the mirror-ocp-release.sh script
```
./mirror-ocp-release.sh
```

# To mirror an OpenShift release and host OpenShift Binaries for UBI deployments
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-full.sh
```

* run the ./mirror-ocp-full.sh
```
./mirror-ocp-full.sh
```

# To mirror an OpenShift release and host OpenShift Binaries for assisted installer deployments
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-full.sh
```
* run the get-ai-svc-version.sh
```
./get-ai-svc-version.sh
```

* run the ./mirror-ocp-full.sh
```
./mirror-ocp-full.sh
```
