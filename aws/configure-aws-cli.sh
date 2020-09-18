#!/bin/bash
set -xe 

if [ "$#" -ne 3 ];
then 
  echo "Please pass required arguments"
  echo "USAGE: $0 aws_access_key_id aws_secret_access_key aws_region"
  exit $1
fi 

if [ "$EUID" -ne 0 ]
  then 
  RUN_SUDO="sudo"
fi


curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip

${RUN_SUDO} ./aws/install

aws --version || exit 1

if [ "$EUID" -ne 0 ]
then
  rm -rf ${HOME}/awscli-bundle ${HOME}/awscli-bundle.zip 
else
  rm -rf /root/awscli-bundle /root/awscli-bundle.zip 
fi

export AWSKEYID=${1}
export AWSSECRETKEY=${2}
export REGION=${3}

mkdir -p $HOME/.aws
cat  >$HOME/.aws/credentials<<EOF
[default]
aws_access_key_id = ${AWSKEYID}
aws_secret_access_key = ${AWSSECRETKEY}
region = ${REGION}
EOF

cat $HOME/.aws/credentials

aws sts get-caller-identity || exit $?

