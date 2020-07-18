#!/bin/bash

echo -e "Enter a password file name to create (blank to quit) "
read 'PASSWORDFILE'
if [ $(expr length "$PASSWORDFILE") -eq 0 ]
then
  echo "script exiting upon your request"
  exit 
fi
if [ -f "/tmp/${PASSWORDFILE}" ] || [ -r "/tmp/${PASSWORDFILE}.cleartext" ]
then 
  echo "/tmp/${PASSWORDFILE} or /tmp/${PASSWORDFILE}.cleartext exists. Quitting.."
  exit
fi
touch "/tmp/${PASSWORDFILE}"
touch "/tmp/${PASSWORDFILE}.cleartext"
while true 
do 
	echo -e "enter user name to create or a blank name to quit: "
  read USERNAME
  if [ $(expr length "$USERNAME") -ne 0 ]
  then
    echo -e "enter a password or a blank like for a randomly generated password : "
    read PASSWORD
    if [ $(expr length "$PASSWORD") -eq 0 ]
    then
      PASSWORD=$(openssl rand -base64 16)
    fi
    htpasswd -B -b /tmp/${PASSWORDFILE} ${USERNAME} ${PASSWORD}
	  echo -e "${USERNAME}  ${PASSWORD}" >> /tmp/${PASSWORDFILE}.cleartext
  else
    break 
  fi
done
echo -e "Your password file is at /tmp/${PASSWORDFILE} and your requests file is at /tmp/${PASSWORDFILE}.cleartext \n"
