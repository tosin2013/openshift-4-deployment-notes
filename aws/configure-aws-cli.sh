#!/bin/bash

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip 

./awscli-bundle/install -i /usr/local/aws -b /bin/aws 

aws --version || exit 1

rm -rf /root/awscli-bundle /root/awscli-bundle.zip 


cat >source_me<<EOF
export AWSKEY=changekey
export AWSSECRETKEY=changekey
export REGION=your-region
EOF

source  source_me

mkdir $HOME/.aws
cat  >$HOME/.aws/credentials<<EOF
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = ${REGION}
EOF

cat $HOME/.aws/credentials

aws sts get-caller-identity 

