#!/bin/bash 

for i in {1..3}
do
    echo "ocp4-master${i}"
    VIRSH_VM="ocp4-master${i}"
    if [[ ! -z "${VIRSH_VM}" ]]; then
    echo "  Deleting VM ${VIRSH_VM} ..."
    sudo virsh shutdown ${VIRSH_VM}
    sudo virsh undefine ${VIRSH_VM}
    fi
done


for i in {1..3}
do
    echo "ocp4-master${i}"
    VIRSH_VM="ocp4-master${i}"
    if [[ -f "${LIBVIRT_VM_PATH}/${VIRSH_VM}.qcow2" ]]; then
    echo "  Deleting disk for VM${VIRSH_VM}) at ${LIBVIRT_VM_PATH}/${VIRSH_VM}.qcow2 ..."
    sudo rm ${LIBVIRT_VM_PATH}/${VIRSH_VM}.qcow2 || true
    fi
done
