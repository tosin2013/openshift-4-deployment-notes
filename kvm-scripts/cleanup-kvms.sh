#!/bin/bash 

function cleanup(){
    #clean up 
    sudo virsh destroy bootstrap && sudo virsh undefine bootstrap --remove-all-storage

    for i in {1..3}
    do 
        sudo virsh destroy master-0${i} && sudo virsh undefine master-0${i} --remove-all-storage
    done 

    for i in {1..2}
    do 
        sudo virsh destroy worker-0${i} && sudo virsh undefine worker-0${i} --remove-all-storage
    done 
}

cleanup