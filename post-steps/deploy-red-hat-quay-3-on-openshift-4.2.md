# DEPLOY RED HAT QUAY 3 ON OPENSHIFT 4.2

**Log in with oc cli. Login as a user with cluster scope permissions to the OpenShift cluster.**
```
$ oc login -u system:admin
```

**1. Set up the Red Hat Quay namespace and secrets**
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Namespace  
metadata:
  name: quay-enterprise
EOF

$ oc project quay-enterprise

or

$ oc new-project quay-enterprise
```
*Create the secret for the Red Hat Quay configuration and app*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Secret
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-config-secret
EOF

$ oc create secret generic quay-enterprise-secret
```

**Create a secret that includes your credentials, as follows:**

```
$ cat >dockerconfig.json<<EOF
{
"auths":{

   "quay.io": {
        "auth":
"Change Me",
        "email": ""
       }
    }
}
EOF
```

```
$ oc create secret generic  redhat-quay-pull-secret     --from-file=".dockerconfigjson=dockerconfig.json" --type='kubernetes.io/dockerconfigjson' -n quay-enterprise
```


**2. Create the Red Hat Quay database**
*Create Quay StorageClass*
**if you are using a different storage class define it in your persistentvolumeclaims**
```
$ cat <<EOF | oc create -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: quay-storageclass
parameters:
  type: gp2
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
EOF
```

*Create persistentvolumeclaim for postgress*
*db-pvc.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-storage
  namespace: quay-enterprise
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 5Gi
  storageClassName: quay-storageclass
EOF
```

*Deploy Postgress*
*Set username and password*
```
POSTGRESS_USER=admin
POSTGRESS_PASSWORD=openshift
```
*postgres-deployment.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: postgres
  namespace: quay-enterprise
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: registry.access.redhat.com/rhscl/postgresql-10-rhel7:1-35
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 5432
          env:
          - name: POSTGRESQL_USER
            value: "${POSTGRESS_USER}"
          - name: POSTGRESQL_DATABASE
            value: "quay"
          - name: POSTGRESQL_PASSWORD
            value: "${POSTGRESS_PASSWORD}"
          volumeMounts:
            - mountPath: /var/lib/pgsql/data
              name: postgredb
          serviceAccount: postgres
          serviceAccountName: postgres
      volumes:
          - name: postgredb
            persistentVolumeClaim:
              claimName: postgres-storage
EOF
```

*Create postgres service*
*postgres-service.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: quay-enterprise
  labels:
    app: postgres
spec:
  type: NodePort
  ports:
   - port: 5432
  selector:
   app: postgres
EOF
```

*List running pods*
```
$ oc get pods -n quay-enterprise
NAME                        READY   STATUS    RESTARTS   AGE
postgres-xxxxxxxxxx-xxxxx   1/1     Running   0          3m26s
```

*Run the following command with the name of your pod*
```
$ oc exec -it postgres-xxxxxxxxxx-xxxxx -n quay-enterprise -- /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | /opt/rh/rh-postgresql10/root/usr/bin/psql -d quay'
```

*Create a serviceaccount for the database*
```
$ oc create serviceaccount postgres -n quay-enterprise
serviceaccount/postgres created
$ oc adm policy add-scc-to-user anyuid -z system:serviceaccount:quay-enterprise:postgres \
scc "anyuid" added to: ["system:serviceaccount:quay-enterprise:system:serviceaccount:quay-enterprise:postgres"]
```

**4. Create Red Hat Quay roles and privileges**
*Create the role and the role binding*
*quay-servicetoken-role-k8s1-6.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: quay-enterprise-serviceaccount
  namespace: quay-enterprise
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - put
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
- apiGroups:
  - extensions
  - apps
  resources:
  - deployments
  verbs:
  - get
  - list
  - patch
  - update
  - watch
EOF
```

*quay-servicetoken-role-binding-k8s1-6.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: quay-enterprise-secret-writer
  namespace: quay-enterprise
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: quay-enterprise-serviceaccount
subjects:
- kind: ServiceAccount
  name: default
EOF
```

*Make sure that the service account has root privileges, because Red Hat Quay runs strictly under root*
```
$ oc adm policy add-scc-to-user anyuid \
     system:serviceaccount:quay-enterprise:default
```

**5. Create the Redis deployment**
*Deploy Redis Database using quay-enterprise-redis.yaml*

```
$ cat <<EOF | oc create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-redis
  labels:
    quay-enterprise-component: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      quay-enterprise-component: redis
  template:
    metadata:
      namespace: quay-enterprise
      labels:
        quay-enterprise-component: redis
    spec:
      containers:
      - name: redis-master
        image: registry.access.redhat.com/rhscl/redis-32-rhel7
        imagePullPolicy: "IfNotPresent"
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-redis
  labels:
    quay-enterprise-component: redis
spec:
  ports:
    - port: 6379
  selector:
    quay-enterprise-component: redis
EOF
```

**6. Prepare to configure Red Hat Quay**
*Set up to configure Red Hat Quay:*

*quay-enterprise-config.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-config-app
  labels:
    quay-enterprise-component: config-app
spec:
  replicas: 1
  selector:
    matchLabels:
      quay-enterprise-component: config-app
  template:
    metadata:
      namespace: quay-enterprise
      labels:
        quay-enterprise-component: config-app
    spec:
      containers:
      - name: quay-enterprise-config-app
        image: quay.io/redhat/quay:v3.2.0
        ports:
        - containerPort: 8443
        command: ["/quay-registry/quay-entrypoint.sh"]
        args: ["config", "secret"]
      imagePullSecrets:
        - name: redhat-quay-pull-secret
EOF
```

*quay-enterprise-config-service-clusterip.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-config
spec:
  type: ClusterIP
  ports:
    - protocol: TCP
      name: https
      port: 443
      targetPort: 8443
  selector:
    quay-enterprise-component: config-app
EOF
```

*quay-enterprise-config-route.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Route
metadata:
  name: quay-enterprise-config
  namespace: quay-enterprise
spec:
  to:
    kind: Service
    name: quay-enterprise-config
  tls:
    termination: passthrough
EOF
```

7. Start the Red Hat Quay configuration user interface
*Start the Red Hat Quay application*
*quay-enterprise-service-clusterip.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-clusterip
spec:
  type: ClusterIP
  ports:
    - protocol: TCP
      name: https
      port: 443
      targetPort: 8443
  selector:
    quay-enterprise-component: app
EOF
```

*quay-enterprise-app-route.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Route
metadata:
  name: quay-enterprise
  namespace: quay-enterprise
spec:
  to:
    kind: Service
    name: quay-enterprise-clusterip
  tls:
    termination: passthrough
EOF
```

*quay-enterprise-app-rc.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: quay-enterprise
  name: quay-enterprise-app
  labels:
    quay-enterprise-component: app
spec:
  replicas: 1
  selector:
    matchLabels:
      quay-enterprise-component: app
  template:
    metadata:
      namespace: quay-enterprise
      labels:
        quay-enterprise-component: app
    spec:
      volumes:
        - name: configvolume
          secret:
            secretName: quay-enterprise-secret
      containers:
      - name: quay-enterprise-app
        image: quay.io/redhat/quay:v3.2.0
        ports:
        - containerPort: 8443
        volumeMounts:
        - name: configvolume
          readOnly: false
          mountPath: /conf/stack
      imagePullSecrets:
        - name: redhat-quay-pull-secret
EOF
```
9. Deploy the Red Hat Quay configuration

**Log in as quayconfig:**
User Name: quayconfig
Password: secret

**Select "Start new configuration for this cluster"**

**Configure Database**
![postgress database](https://i.imgur.com/MjnMw2J.png)

**Configure admin user**
![Configure Admin user](https://i.imgur.com/TTiyPtw.png)

**Optional Settings**
Custom SSL Certificates: Upload custom or self-signed SSL certificates for use by Red Hat Quay. See Using SSL to protect connections to Red Hat Quay for details. Recommended for high availability.

> IMPORTANT
> Using SSL certificates is recommended for both basic and high availability deployments. If you decide to not use SSL, you must configure your container clients to use your new Red Hat Quay setup as an insecure registry as described in Test an Insecure Registry.
>

**Server Configuration:**
Hostname or IP address to reach the Red Hat Quay service, along with TLS indication (recommended for production installations). To get the route to the permanent Red Hat Quay service, type the following:
```
$ oc get route -n quay-enterprise quay-enterprise
NAME            HOST/PORT                                                               PATH SERVICES                  PORT TERMINATION WILDCARD
quay-enterprise quay-enterprise-quay-enterprise.apps.example.com    quay-enterprise-clusterip <all>            None

Get quay-enterprise-quay-enterprise.apps.example.com
```

See [Using SSL to protect connections](https://access.redhat.com/documentation/en-us/red_hat_quay/3/html-single/manage_red_hat_quay/index#using-ssl-to-protect-quay) to Red Hat Quay. TLS termination can be done in two different ways:

On the instance itself, with all TLS traffic governed by the nginx server in the quay container (recommended).
On the load balancer. This is not recommended. Access to Red Hat Quay could be lost if the TLS setup is not done correctly on the load balancer.
```
$ openssl genrsa -out rootCA.key 2048
$ openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:US
State or Province Name (full name) []:Georgia
Locality Name (eg, city) []:Atlanta
Organization Name (eg, company) []:Red Hat
Organizational Unit Name (eg, section) []:Sales
Common Name (eg, fully qualified host name) []:*.apps.example.com
Email Address []:user@example.com

$ openssl genrsa -out device.key 2048
$ openssl req -new -key device.key -out device.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:US
State or Province Name (full name) []:Georgia
Locality Name (eg, city) []:Atlanta
Organization Name (eg, company) []:Red Hat
Organizational Unit Name (eg, section) []:Sales
Common Name (eg, fully qualified host name) []:*.apps.example.com
Email Address []:user@example.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:p@$$w@rd

$ openssl x509 -req -in device.csr -CA rootCA.pem \
       -CAkey rootCA.key -CAcreateserial -out device.crt -days 500 -sha256
```
**Upload certs to Console**
![](https://i.imgur.com/LRsOq8G.png)

![](https://i.imgur.com/Klu7AMT.png)

**Configure Redis**
*Get hostname*
```
$ oc get svc | grep redis
quay-enterprise-redis       ClusterIP   172.30.202.60    <none>        6379/TCP         10m
```

**On Failues**
> If for some reason the deployment doesn’t complete, try deleting the quay-enterprise-app pod. OpenShift should create a new pod and pick up the needed configuration. If that doesn’t work, unpack the configuration files (tar xvf quay-config.tar.gz) and add them manually to the secret:
>
> ```
> $ oc delete secret quay-enterprise-secret -n quay-enterprise
> ```
>
> ```
> $ oc create secret generic quay-enterprise-secret -n quay-enterprise \
>      --from-file=config.yaml=config.yaml \
>      --from-file=ssl.key=device.key \
>      --from-file=ssl.cert=device.crt
> ```
>
> ```
> $ oc get pods
> NAME                                         READY   STATUS    RESTARTS   AGE
> postgres-xxxxxx-xxxxx                   1/1     Running   2          47h
> quay-enterprise-app-xxxxxx-xxxxx          1/1     Running   0          2m6s
> quay-enterprise-config-app-xxxxxx-xxxxx    1/1     Running   0          13m
> quay-enterprise-redis-xxxxxx-xxxxx        1/1     Running   0          13m
> ```
>
>```
> $ oc delete pod quay-enterprise-app-xxxxxx-xxxxx
> ```


11. Add Clair image scanning

*Create the Clair database*

*postgres-clair-storage.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-clair-storage
  namespace: quay-enterprise
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: quay-storageclass
EOF
```

*postgres-clair-deployment.yaml file*

*Set username and password*
```
export POSTGRESS_USER=admin
export POSTGRESS_PASSWORD=openshift
```

```
$ cat <<EOF | oc create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: postgres-clair
  name: postgres-clair
  namespace: quay-enterprise
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-clair
  template:
    metadata:
      labels:
        app: postgres-clair
    spec:
      containers:
      - env:
        - name: POSTGRESQL_USER
          value: $POSTGRESS_USER
        - name: POSTGRESQL_DATABASE
          value: clairdb
        - name: POSTGRESQL_PASSWORD
          value: $POSTGRESS_PASSWORD
        image: registry.access.redhat.com/rhscl/postgresql-10-rhel7:1-35
        imagePullPolicy: IfNotPresent
        name: postgres-clair
        ports:
        - containerPort: 5432
          protocol: TCP
        volumeMounts:
        - mountPath: /var/lib/pgsql/data
          name: postgredb
        serviceAccount: postgres
        serviceAccountName: postgres
      volumes:
      - name: postgredb
        persistentVolumeClaim:
          claimName: postgres-clair-storage
EOF
```

*postgres-clair-service.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: postgres-clair
  name: postgres-clair
  namespace: quay-enterprise
spec:
  ports:
  - nodePort: 30680
    port: 5432
    protocol: TCP
    targetPort: 5432
  selector:
    app: postgres-clair
  type: NodePort
EOF
```

*Check Clair database objects*
```
$ oc get all | grep -i clair
pod/postgres-clair-xxxxxxxxx-xxxx 1/1      Running       0                     3m45s
deployment.apps/postgres-clair    1/1      1             1                     3m45s
service/postgres-clair            NodePort 172.30.193.64 <none> 5432:30680/TCP 159m
replicaset.apps/postgres-clair-xx 1        1             1                     3m45s
```
**Open the Red Hat Quay Setup UI:**
* Reload the Red Hat Quay Setup UI and select "Modify configuration for this cluster."
* *Enable Security Scanning:* Scroll to the Security Scanner section and select the **"Enable Security Scanning"** checkbox. From the fields that appear you need to create an authentication key and enter the security scanner endpoint.
* Generate key: Click **"Create Key"** and then type a name for the Clair private key and an optional expiration date (if blank, the key never expires). Then select Generate Key.
* Copy the Clair key and PEM file: Save the Key ID (to a notepad or similar) and download a copy of the Private Key PEM file (named security_scanner.pem) by selecting "Download Private Key" (if you lose this key, you will need to generate a new one).
* Modify clair-config.yaml: Return to the shell and the directory holding your yaml files. Edit the clair-config.yaml file and modify the following values:

```
# The ID of the service key generated for Clair. The ID is returned when setting up
# the key in [Quay Enterprise Setup](security-scanning.md)
export KEYID=XXXXXXXXXXX
cat >clair-config.yaml<<EOF
clair:
  database:
    type: pgsql
    options:
      source: host=postgres-clair port=5432 dbname=clairdb user=$POSTGRESS_USER password=$POSTGRESS_PASSWORD sslmode=disable
      cachesize: 16384
  api:
    # The port at which Clair will report its health status. For example, if Clair is running at
    # https://clair.mycompany.com, the health will be reported at
    # http://clair.mycompany.com:6061/health.
    healthport: 6061

    port: 6062
    timeout: 900s

    # paginationkey can be any random set of characters. *Must be the same across all Clair
    # instances*.
    paginationkey: "XxoPtCUzrUv4JV5dS+yQ+MdW7yLEJnRMwigVY/bpgtQ="

  updater:
    # interval defines how often Clair will check for updates from its upstream vulnerability databases.
    interval: 6h
  notifier:
    attempts: 3
    renotifyinterval: 1h
    http:
      # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
      # For example: https://myregistry.mycompany.com
      endpoint: http://quay-enterprise-clusterip/secscan/notify
      proxy: http://localhost:6063

jwtproxy:
  signer_proxy:
    enabled: true
    listen_addr: :6063
    ca_key_file: /certificates/mitm.key # Generated internally, do not change.
    ca_crt_file: /certificates/mitm.crt # Generated internally, do not change.
    signer:
      issuer: security_scanner
      expiration_time: 5m
      max_skew: 1m
      nonce_length: 32
      private_key:
        type: preshared
        options:
          # The ID of the service key generated for Clair. The ID is returned when setting up
          # the key in [Quay Enterprise Setup](security-scanning.md)
          key_id: $KEYID
          private_key_path: /clair/config/security_scanner.pem

  verifier_proxies:
  - enabled: true
    # The port at which Clair will listen.
    listen_addr: :6060

    # If Clair is to be served via TLS, uncomment these lines. See the "Running Clair under TLS"
    # section below for more information.
    # key_file: /config/clair.key
    # crt_file: /config/clair.crt

    verifier:
      # CLAIR_ENDPOINT is the endpoint at which this Clair will be accessible. Note that the port
      # specified here must match the listen_addr port a few lines above this.
      # Example: https://myclair.mycompany.com:6060
      audience: http://clair-service:6060

      upstream: http://localhost:6062
      key_server:
        type: keyregistry
        options:
          # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
          # Example: https://myregistry.mycompany.com
          registry: http://quay-enterprise-clusterip/keys/
EOF
```

*Save security_scanner.pem*
```
cat >security_scanner.pem<<EOF
-----BEGIN RSA PRIVATE KEY-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
-----END RSA PRIVATE KEY-----
EOF
```

*Create the Clair config secret:*
```
$ oc create secret generic clair-scanner-config-secret \
   --from-file=config.yaml=clair-config.yaml \
   --from-file=security_scanner.pem=security_scanner.pem
```

*Create the Clair config secret:
*clair-service.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  name: clair-service
  namespace: quay-enterprise
spec:
  ports:
  - name: clair-api
    port: 6060
    protocol: TCP
    targetPort: 6060
  - name: clair-health
    port: 6061
    protocol: TCP
    targetPort: 6061
  selector:
    quay-enterprise-component: clair-scanner
type: ClusterIP
EOF
```

*clair-deployment.yaml file*
```
$ cat <<EOF | oc create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    quay-enterprise-component: clair-scanner
  name: clair-scanner
  namespace: quay-enterprise
spec:
  replicas: 1
  selector:
    matchLabels:
      quay-enterprise-component: clair-scanner
  template:
    metadata:
      labels:
        quay-enterprise-component: clair-scanner
      namespace: quay-enterprise
    spec:
      containers:
      - image: quay.io/redhat/clair-jwt:v3.2.0
        imagePullPolicy: IfNotPresent
        name: clair-scanner
        ports:
        - containerPort: 6060
          name: clair-api
          protocol: TCP
        - containerPort: 6061
          name: clair-health
          protocol: TCP
        volumeMounts:
        - mountPath: /clair/config
          name: configvolume
      imagePullSecrets:
      - name: redhat-quay-pull-secret
      restartPolicy: Always
      volumes:
      - name: configvolume
        secret:
          secretName: clair-scanner-config-secret
EOF
```

*Get the clair-service endpoint:*
```
$ oc get service clair-service
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
clair-service   ClusterIP   172.30.41.81   <none>        6060/TCP,6061/TCP   13m
```

*Enter Security Scanner Endpoint:*
Return to the Red Hat Quay Setup screen and fill in the clair-service endpoint. `Example: http://172.30.41.81:6060`

*Deploy configuration:*
Select to save the configuration, then deploy it when prompted.

> If the clair scanner does not populate in quay perform the below steps
>
> If for some reason the deployment doesn’t complete, try deleting the quay-enterprise-app pod. OpenShift should create a new pod and pick up the needed configuration. If that doesn’t work, unpack the configuration files (tar xvf quay-config.tar.gz) and add them manually to the secret:
> ```
> $ oc delete secret quay-enterprise-secret -n quay-enterprise
> $ oc create secret generic quay-enterprise-secret -n quay-enterprise \
>      --from-file=config.yaml=config.yaml \
>      --from-file=ssl.key=device.key \
>      --from-file=ssl.cert=device.crt
> $ oc get pods
> NAME                                         READY   STATUS    RESTARTS   AGE
> postgres-xxxxxx-xxxxx                   1/1     Running   2          47h
> quay-enterprise-app-xxxxxx-xxxxx          1/1     Running   0          2m6s
> quay-enterprise-config-app-xxxxxx-xxxxx    1/1     Running   0          13m
> quay-enterprise-redis-xxxxxx-xxxxx        1/1     Running   0          13m
> $ oc delete pod quay-enterprise-app-xxxxxx-xxxxx
> ```

Links:
[Configuring Red Hat OpenShift Container Storage for Red Hat Quay](https://access.redhat.com/articles/4356091)
[DEPLOY RED HAT QUAY ON OPENSHIFT](https://access.redhat.com/documentation/en-us/red_hat_quay/3/html-single/deploy_red_hat_quay_on_openshift/index)
[EVALUATE RED HAT QUAY](https://access.redhat.com/products/red-hat-quay/evaluation)
