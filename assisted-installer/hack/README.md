# Hack-y scripts

> See [Configure System](https://github.com/kenmoini/ocp4-ai-svc-libvirt/tree/main/scripts) to configure single node server for testing.
```
curl -OL https://gist.githubusercontent.com/tosin2013/ae925297c1a257a1b9ac8157bcc81f31/raw/71a798d427a016bbddcc374f40e9a4e6fd2d3f25/configure-rhel8.x.sh
chmod +x configure-rhel8.x.sh
./configure-rhel8.x.sh
```


### Download and extract the qubinode-installer as a non root user.
> qubinode will quickly configure a kvm enviornment to test with. 
```
cd $HOME
git clone https://github.com/tosin2013/qubinode-installer.git
cd qubinode-installer
git checkout rhel-8.6
```

### Run the qubinode installer to setup the host
```
cd ~/qubinode-installer
./qubinode-installer -m setup
./qubinode-installer -m rhsm
./qubinode-installer -m ansible
./qubinode-installer -m host
```

### Clone repo
```
cd $HOME
git clone https://github.com/tosin2013/openshift-4-deployment-notes.git
cd openshift-4-deployment-notes/assisted-installer/
```

### Build the ISO using the Assisted Installer Scripts
[Assisted Installer Scripts](../)

### Call these scripts from the main `assisted-installer/` directory, like: `./hack/create-kvm-vms.sh`

- `create-kvm-vms.sh` creates VMs to test on a Libvirt host
- `delete-kvm-vms.sh` deletes VMs on a Libvirt host that were used for testing
- `watch-and-reboot-kvm-vms.sh` will watch Libvirt/KVM via `virsh` and restarts them due to a bug in `virt-install`
