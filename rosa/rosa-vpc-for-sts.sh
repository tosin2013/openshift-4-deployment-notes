#!/bin/bash
set -xe 
# Print usage
function usage() {
  echo -n "${0} [OPTION]
 Options:
  -c      OpenShift Cluster Name
  -r      AWS Region
  To deploy VPC for rosa sts 
  ${0}  -c private-link -r us-east-2
"
}

if [ -z "$1" ];
then
  usage
  exit 0
fi

while getopts ":c:r:h:" arg; do
  case $arg in
    h) export  HELP=True;;
    c) export  ROSA_CLUSTER_NAME=$OPTARG;;
    r) export  AWS_REGION=$OPTARG;;
  esac
done

function checkForProgramAndExit() {
    command -v $1 > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        printf '%-72s %-7s\n' $1 "PASSED!";
    else
        printf '%-72s %-7s\n' $1 "FAILED!";
        exit 1
    fi
}


if [[ "$1" == "-h" ]];
then
  usage
  exit 0
fi

echo ${ROSA_CLUSTER_NAME} ${AWS_REGION}
export VPC_CIDR="10.0.0.0/16"
export PUBLIC_CIDR="10.0.128.0/17"
export PRIVATE_CIDR="10.0.0.0/17"
checkForProgramAndExit jq
checkForProgramAndExit aws


VPC_ID=`aws ec2 create-vpc --cidr-block ${VPC_CIDR} | jq -r .Vpc.VpcId`

aws ec2 create-tags --resources $VPC_ID \
   --tags Key=Name,Value=$ROSA_CLUSTER_NAME | jq .

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames | jq .


PUBLIC_SUBNET=`aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block ${PUBLIC_CIDR} | jq -r .Subnet.SubnetId`

aws ec2 create-tags --resources $PUBLIC_SUBNET \
   --tags Key=Name,Value=$ROSA_CLUSTER_NAME-public | jq .

PRIVATE_SUBNET=`aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block ${PRIVATE_CIDR} | jq -r .Subnet.SubnetId`

aws ec2 create-tags --resources $PRIVATE_SUBNET \
   --tags Key=Name,Value=$ROSA_CLUSTER_NAME-private | jq .

I_GW=`aws ec2 create-internet-gateway | jq -r .InternetGateway.InternetGatewayId`
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $I_GW | jq .

aws ec2 create-tags --resources $I_GW \
--tags Key=Name,Value=$ROSA_CLUSTER_NAME | jq .

R_TABLE=`aws ec2 create-route-table --vpc-id $VPC_ID | jq -r .RouteTable.RouteTableId`

aws ec2 create-route --route-table-id $R_TABLE --destination-cidr-block 0.0.0.0/0 --gateway-id $I_GW | jq .

aws ec2 describe-route-tables --route-table-id $R_TABLE | jq .

aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET --route-table-id $R_TABLE | jq .

aws ec2 create-tags --resources $R_TABLE \
--tags Key=Name,Value=$ROSA_CLUSTER_NAME | jq .

EIP=`aws ec2 allocate-address --domain vpc | jq -r .AllocationId`
NAT_GW=`aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET \
--allocation-id $EIP | jq -r .NatGateway.NatGatewayId`

aws ec2 create-tags --resources $EIP --resources $NAT_GW \
--tags Key=Name,Value=$ROSA_CLUSTER_NAME | jq .

R_TABLE_NAT=`aws ec2 create-route-table --vpc-id $VPC_ID | jq -r .RouteTable.RouteTableId`

while ! aws ec2 describe-route-tables --route-table-id $R_TABLE_NAT \
| jq .; do sleep 1; done

aws ec2 create-route --route-table-id $R_TABLE_NAT --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT_GW | jq .

aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET --route-table-id $R_TABLE_NAT | jq .

aws ec2 create-tags --resources $R_TABLE_NAT $EIP \
--tags Key=Name,Value=$ROSA_CLUSTER_NAME-private | jq .

echo "Run the following command to deploy ROSA"
echo "rosa init --region ${AWS_REGION}" >   ~/deploy-rosa-${ROSA_CLUSTER_NAME}.sh
echo "rosa create cluster --private-link --cluster-name=${ROSA_CLUSTER_NAME} --machine-cidr=${VPC_CIDR} --subnet-ids=${PRIVATE_SUBNET}  --region ${AWS_REGION}" | tee -a  ~/deploy-rosa-${ROSA_CLUSTER_NAME}.sh
echo "rosa logs install --cluster=${ROSA_CLUSTER_NAME} --watch" | tee -a  ~/deploy-rosa-${ROSA_CLUSTER_NAME}.sh
chmod +x ~/deploy-rosa-${ROSA_CLUSTER_NAME}.sh