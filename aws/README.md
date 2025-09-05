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

3. Configure OpenShift Packages -> [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh)
```
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
chmod +x configure-openshift-packages.sh
./configure-openshift-packages.sh -i
```

4. Configure and start OpenShift installer ->[configure-openshift-installer.sh](configure-openshift-installer.sh)
```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cluster-key -N ''

chmod 400 ~/.ssh/cluster-key.pub
cat  ~/.ssh/cluster-key.pub

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key 
openshift-install create cluster --dir $HOME/cluster --log-level debug
```
### Optional 
**Install Kustomize by downloading precompiled binaries.**
```
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo mv kustomize /usr/local/bin
```

**Installing Helm**
```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
$ sudo mv helm /usr/local/bin
```
