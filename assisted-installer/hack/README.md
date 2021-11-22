# Hack-y scripts

Call these scripts from the main `assisted-installer/` directory, like: `./hack/create-kvm-vms.sh`

- `create-kvm-vms.sh` creates VMs to test on a Libvirt host
- `delete-kvm-vms.sh` deletes VMs on a Libvirt host that were used for testing
- `watch-and-reboot-kvm-vms.sh` will watch Libvirt/KVM via `virsh` and restarts them due to a bug in `virt-install`