#!/bin/bash

##
# Configure dhcp config
##
SUBNET="192.168.1."
START_AT="75"
echo "" > pxelinux
for x in ${COMPUTERNAMES}
do 
  echo "********************************"
  echo "* Collecting Network info on $x*"
  echo "********************************"
  #MACADDRESS=$(sudo  virsh dumpxml $x | grep "mac address"  | awk -F\' '{ print $2}')
  MACADDRESS=$(sudo  virsh domiflist $x | grep e1000 | awk '{print $5}')
  ((START_AT=START_AT+1))
  echo "host $x { hardware ethernet ${MACADDRESS}; fixed-address ${SUBNET}${START_AT}; }" >> pxelinux
done 
cat pxelinux