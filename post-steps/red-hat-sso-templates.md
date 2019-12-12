# Configuring RH-SSO on OpenShift 4
This documentation details how to configure Red Hat Single Sign-On 7.3 to be used for authentication to OpenShift.

**Source variables**
```
export PROJECT_NAME=rh-sso-openshift
export URL_ENDPOINT="apps.ocp42.qubinodetest.com"
```

**Create new project**
```
oc new-project ${PROJECT_NAME}
```

**Add the view role to the default service account.**
```
oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default
```

**Deploy RH-SSO**
Note: This is an in-memory deployment of sso73 use a different one for persistent storage.
```
oc new-app --template=sso73-x509-https
```

**Login to RH-SSO**
```
echo "LOGIN URL: https://$(oc get routes | grep sso | awk '{print $2}')"
```

**Please See 5.3.1. Configuring Red Hat Single Sign-On Credentials**  
[Example Workflow: Configuring OpenShift to use Red Hat Single Sign-On for Authentication](https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.3/html-single/red_hat_single_sign-on_for_openshift/index#OSE-SSO-AUTH-TUTE)


**Download JQ**
```
curl -OL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
mv jq-linux64 /usr/local/bin/jq
jq --version
```

**Display openid-configuration from RH-SSO**
```
FQDN=ocp4.example.com
OS_REALM="openshift-realm"
curl -k https://sso-rh-sso-openshift.apps.${FQDN}.com/auth/realms/${OS_REALM}/.well-known/openid-configuration | python -m json.tool
```

**Get Issuer information**
```
FQDN=ocp4.example.com
OS_REALM="openshift-realm"
PROJECT_NAME="rh-sso-openshift"
curl -sk https://sso-${PROJECT_NAME}.apps.${FQDN}/auth/realms/.well-known/${OS_REALM}/openid-configuration | jq .issuer
```

**example Valid Redirect URL**
```
FQDN=ocp4.example.com
METATAGNAME="openid"
echo "	The client ID of a client registered with the OpenID provider. The client must be allowed to redirect to"
echo "https://oauth-openshift.apps.${FQDN}.com/oauth2callback/${METATAGNAME}"
```

**Get OpenShift Router Cert to be used for rh-sso**
```
oc get cm/router-ca -n openshift-config-managed -o jsonpath='{.data.ca\-bundle\.crt}' > openshift-router.crt
```

### Configure identity providers using the web console
1. Navigate to Administration → Cluster Settings.
2. Under the Global Configuration tab, click OAuth.
3. Under the Identity Providers section, select your identity provider from the Add drop-down menu.  
[Configuring identity providers using the web console](https://docs.openshift.com/container-platform/4.2/authentication/identity_providers/configuring-oidc-identity-provider.html#identity-provider-configuring-using-the-web-console_configuring-oidc-identity-provider)

### WIP - Using CLI to configure identity provider
**Source Variables**
```
export SECRET_NAME="client-secret"
export SECRET="xxx-xxx-xxx-xxx"
export FQDN=ocp4.example.com
export CLIENTID="openshift-login"
export METATAGNAME="openid"
export REALM="openshift-realm"
export PROJECT_NAME="rh-sso-openshift"
```

**Create Create**
```
oc create secret generic ${SECRET_NAME} --from-literal=clientSecret=${SECRET} -n openshift-config
```

**Creating ConfigMap**
```
oc create configmap ca-config-map --from-file=ca.crt=openshift-router.crt -n openshift-config
```

**Example Template**
```
cat >rh-sso-identiy-provider.yml<<YAML
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
    - mappingMethod: claim
      name: ${METATAGNAME}
      openID:
        ca:
          name: ${PROJECT_NAME}
        claims:
          email:
            - email
          name:
            - name
          preferredUsername:
            - preferred_username
        clientID: openshift-login
        clientSecret:
          name: ${SECRET}
        extraScopes: []
        issuer: >-
          https://sso-${PROJECT_NAME}.apps.${FQDN}/auth/realms/${REALM}
      type: OpenID
YAML
```

**Validate yaml file**
```
cat rh-sso-identiy-provider.yml
```

**Apply the defined CR**
```
oc apply -f rh-sso-identiy-provider.yml
```

**Test Login**
```
oc login -u <username>
oc whoami
```
