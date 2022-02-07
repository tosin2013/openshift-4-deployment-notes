#!/bin/sh
#
# Delete a VPC and its dependencies

# Print usage
function usage() {
  echo -n "${0} [OPTION]
 Options:
  -v      OpenShift Cluster Name
  -r      AWS Region
  To delete VPC for rosa sts 
  ${0}  -v vpc-xxxxxxxxxx  -r us-east-2
"
}

if [ -z "$1" ];
then
  usage
  exit 0
fi

while getopts ":v:r:h:" arg; do
  case $arg in
    h) export  HELP=True;;
    v) export  vpcid=$OPTARG;;
    r) export  AWS_REGION=$OPTARG;;
  esac
done

if [ -z $vpcid ] && [ -z $AWS_REGION ] ;
then 
    usage
    exit 0
fi 

# remove elastic ip
aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='${vpcid} | grep InternetGatewayId
aws ec2 describe-subnets --filters 'Name=vpc-id,Values='${vpcid} | grep SubnetId
aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='${vpcid} | grep RouteTableId
aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='${vpcid} | grep NetworkAclId
aws ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='${vpcid} | grep VpcPeeringConnectionId
aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='${vpcid} | grep VpcEndpointId
aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='${vpcid} | grep NatGatewayId
aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='${vpcid} | grep GroupId
aws ec2 describe-instances --filters 'Name=vpc-id,Values='${vpcid} | grep InstanceId
aws ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='${vpcid} | grep VpnConnectionId
aws ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='${vpcid} | grep VpnGatewayId
aws ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='${vpcid} | grep NetworkInterfaceId

# Delete Nat Gateway 
nat_gateway=$(aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='${vpcid} | grep NatGatewayId| sed -E 's/^.*(nat-[a-z0-9]+).*$/\1/')
aws ec2 delete-nat-gateway --nat-gateway-id ${nat_gateway}

# Delete Route Table
for i in `aws ec2 describe-route-tables --filters Name=vpc-id,Values="${vpcid}" | grep RouteTableId | sed -E 's/^.*(rtb-[a-z0-9]+).*$/\1/'`; do aws ec2 delete-route-table --route-table-id=$i; done

# Delete subnets
for i in `aws ec2 describe-subnets --filters Name=vpc-id,Values="${vpcid}" | grep subnet- | sed -E 's/^.*(subnet-[a-z0-9]+).*$/\1/'`; do aws ec2 delete-subnet --subnet-id=$i; done

# Detach internet gateways
for i in `aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="${vpcid}" | grep igw- | sed -E 's/^.*(igw-[a-z0-9]+).*$/\1/'`; do aws ec2 detach-internet-gateway --internet-gateway-id=$i --vpc-id=${vpcid}; done

# Delete internet gateways
for i in `aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="${vpcid}" | grep igw- | sed -E 's/^.*(igw-[a-z0-9]+).*$/\1/'`; do aws ec2 delete-internet-gateway --internet-gateway-id=$i --vpc-id=${vpcid}; done

# Delete security groups (ignore message about being unable to delete default security group)
for i in `aws ec2 describe-security-groups --filters Name=vpc-id,Values="${vpcid}" | grep sg- | sed -E 's/^.*(sg-[a-z0-9]+).*$/\1/' | sort | uniq`; do aws ec2 delete-security-group --group-id $i; done

# Delete the VPC
aws ec2 delete-vpc --vpc-id ${vpcid}