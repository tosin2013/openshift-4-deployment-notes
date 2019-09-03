# Configure a HTPasswd identity provider 

**Create your file with a user name and hashed password**
```
#!/bin/bash 
USERNAME=user
PASSWORD=$(openssl rand -base64 16)
htpasswd -c -B -b /tmp/passwordFile ${USERNAME} ${PASSWORD}
echo "USERNAME is ${USERNAME} Password: ${PASSWORD}"
```

**add or update credentials to the file**
```
#!/bin/bash
USERNAME=user1
PASSWORD=$(openssl rand -base64 16)
htpasswd -b /tmp/passwordFile  ${USERNAME} ${PASSWORD}
```

**Creating the HTPasswd Secret to use the HTPasswd identity provider**
```
$ oc create secret generic htpass-secret --from-file=htpasswd=/tmp/passwordFile  -n openshift-config
```
**Add an identity provider to your cluster.**
```
#!/bin/bash 
PROVIDER_NAME=users_htpasswd_provider 
cat >htacess-provider.yml<<YAML
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: $PROVIDER_NAME
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
YAML

oc apply -f htacess-provider.yml

USERNAME=user
oc login -u $USERNAME

oc whoami
```


**Optional: Add user to cluster admin role**
```
USERNAME=user
oc adm policy add-cluster-role-to-user cluster-admin $USERNAME
```

### Links:
[Configuring an HTPasswd identity provider](https://docs.openshift.com/container-platform/4.1/authentication/identity_providers/configuring-htpasswd-identity-provider.html#identity-provider-creating-htpasswd-file-linux_configuring-htpasswd-identity-provider)