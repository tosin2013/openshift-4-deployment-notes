# Hack-y scripts

> See [Configure System](https://github.com/kenmoini/ocp4-ai-svc-libvirt/tree/main/scripts) to configure single node server for testing.

### Download and extract the qubinode-installer as a non root user.

```
cd $HOME
wget https://github.com/Qubinode/qubinode-installer/archive/master.zip
unzip master.zip
rm master.zip
mv qubinode-installer-master qubinode-installer
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

### Call these scripts from the main `assisted-installer/` directory, like: `./hack/create-kvm-vms.sh`

- `create-kvm-vms.sh` creates VMs to test on a Libvirt host
- `delete-kvm-vms.sh` deletes VMs on a Libvirt host that were used for testing
- `watch-and-reboot-kvm-vms.sh` will watch Libvirt/KVM via `virsh` and restarts them due to a bug in `virt-install`