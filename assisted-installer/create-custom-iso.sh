#!/bin/bash 
set -xe 

if [ -f ~/offline-token.txt];
then 
  echo "offline-token not found in $HOME directory"
  echo "create offline toket and try again"
  exit 1
fi 

offline_token='$(cat ~/offline-token.txt)'

# curl https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token