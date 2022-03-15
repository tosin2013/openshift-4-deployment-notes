#!/bin/bash 
if [ -z $1 ];
then
  echo "USAGE: Please pass drive name" 
  echo "Example: $0 sdb"
  exit 1
fi 

DRIVE=${1}

mkfs.ext4 /dev/${DRIVE} 2>/dev/null
#create dirctory
mkdir -p /registry/

#mount for start up
echo "/dev/${DRIVE} /registry auto noatime,noexec,nodiratime 0 0" >> /etc/fstab
mount -a /dev/${DRIVE} /registry
