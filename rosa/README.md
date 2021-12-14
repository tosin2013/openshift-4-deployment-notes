# Configure your bastion host to deploy OpenShift

1. Setup bastion node on AWS
2. Configure AWS CLI -> [configure-aws-cli.sh](configure-aws-cli.sh)
```
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/aws/configure-aws-cli.sh
chmod +x configure-aws-cli.sh 
./configure-aws-cli.sh -h
./configure-aws-cli.sh [OPTION]

 Options:
  -i, --install     Install awscli latest binaries
  -d, --delete      Remove awscli
  -h, --help        Display this help and exit

  USAGE: ./configure-aws-cli.sh -i aws_access_key_id aws_secret_access_key aws_region
```
3. Download Rosa 

```
curl -OL https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz
tar -zxvf rosa-linux.tar.gz
chmod +x rosa
mv rosa /usr/local/bin/rosa
rosa completion > /etc/bash_completion.d/rosa
source /etc/bash_completion.d/rosa
```
4. Verify that your AWS account has the necessary permissions.
```
$ rosa login
$ rosa verify permissions
```
5. Verify that your AWS account has the necessary quota to deploy an Red Hat OpenShift Service on AWS cluster.
```
LOCATION=us-west-2
rosa verify quota --region=${LOCATION}
```

6. Prepare your AWS account for cluster deployment:
```
rosa whoami
```

7. Initialize your AWS account. for Rosa Deployment
```
rosa init
```

8. Install the OpenShift CLI (oc) from the rosa CLI.
```
rosa download oc
```

### Deploy ROSA Standard Cluster
> Creating a cluster can take up to 40 minutes.
* Create Cluster with default settings
```
CLUSTER_NAME=poc-cluster
rosa create cluster --cluster-name=${CLUSTER_NAME}
```
* To create a cluster using interactive prompts
```
rosa create cluster --interactive
```

* Track the progress of the cluster creation by watching the OpenShift installer logs
```
CLUSTER_NAME=poc-cluster
rosa logs install --cluster=${CLUSTER_NAME} --watch
```

* Show cluster information 
```
CLUSTER_NAME=poc-cluster
rosa describe cluster --cluster=${CLUSTER_NAME}
```

* Create cluster admin
> 
```
CLUSTER_NAME=poc-cluster
rosa create admin -c ${CLUSTER_NAME} | tee  ${CLUSTER_NAME}.log
```

### Deploy ROSA Standard Cluster
> Creating a cluster can take up to 40 minutes.

* Create VPC for STS deployment
> You may update this example script
```
./rosa-vpc-for-sts.sh private-link us-east-2
```

* To create a Single-AZ cluster
> update variables based of changes in script.
```
CLUSTER_NAME=private-link
VPC_CIDR=10.0.0.0/16
PRIVATE_ID=10.0.0.0/17
AWS_REGION=us-east-2
rosa create cluster --private-link --cluster-name=${CLUSTER_NAME} --machine-cidr=${VPC_CIDR} --subnet-ids=${PRIVATE_SUBNET} --region ${AWS_REGION}
```
* To create a Multi-AZ cluster
```
rosa create cluster --private-link --multi-az --cluster-name=<cluster-name> [--machine-cidr=<VPC CIDR>/16] --subnet-ids=<private-subnet-id1>,<private-subnet-id2>,<private-subnet-id3>
```
* Track the progress of the cluster creation by watching the OpenShift installer logs
```
CLUSTER_NAME=poc-cluster
rosa logs install --cluster=${CLUSTER_NAME} --watch
```

* Show cluster information 
```
CLUSTER_NAME=poc-cluster
rosa describe cluster --cluster=${CLUSTER_NAME}
```

* Create cluster admin
> 
```
CLUSTER_NAME=poc-cluster
rosa create admin -c ${CLUSTER_NAME} | tee  ${CLUSTER_NAME}.log
```


### Deleting a ROSA cluster
```
CLUSTER_NAME=poc-cluster
rosa delete cluster --cluster=${CLUSTER_NAME} --watch
rosa init --delete-stack
```


## Links: 
* [Installing ROSA](https://docs.openshift.com/rosa/rosa_getting_started/rosa-installing-rosa.html)
* [Managed OpenShift Black Belt Team](https://mobb.ninja/docs/rosa/private-link/)
* [Software Site-to-Site VPN](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/software-site-to-site-vpn-1.html)
