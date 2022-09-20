# Ansible Tower on ACM Deployment 
## Getting Started 
### Requirements
* [Set up the main configuration Application for Red Hat Advanced Cluster Management](https://hackmd.io/rKGcWPITQj6EjOE0IlCP8Q)
* [Reference Repo](https://github.com/redhat-cop/gitops-catalog/tree/main/ansible-automation-platform)
* 
###  Ansible Automation Platform Operator
**Create a new directory to hold the policy:**

```bash
mkdir -p $HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-installed

cd $HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-installed
```

**Create a policy ansible-automation-platform in namespace acm-policies that creates all the required objects for the Ansible Automation Platform Operator.**

```bash
cat << EOF >$HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-installed/policy.yaml

---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: ansible-automation-platform-installed
  namespace: acm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: ansible-automation-platform-installed
      spec:
        remediationAction: enforce
        severity: medium
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: operators.coreos.com/v1alpha1
            kind: Subscription
            metadata:
              name: ansible-automation-platform-operator
              namespace: ansible-automation-platform
            spec:
              channel: stable-2.2-cluster-scoped
              installPlanApproval: Automatic
              name: ansible-automation-platform-operator
              source: redhat-operators
              sourceNamespace: openshift-marketplace
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Namespace
            metadata:
              name: ansible-automation-platform
EOF
```

**Create a placement rule named ansible-automation-platform-installed to select all OpenShift clusterswith either label purpose=development or purpose=production.**

```bash
cat << EOF >$HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-installed/placementrule.yaml

---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: ansible-automation-platform-installed
  namespace: acm-policies
spec:
  clusterSelector:
    matchExpressions:
    - key: vendor
      operator: In
      values:
        - OpenShift
    - key: purpose
      operator: In
      values:
        - development
        - production
EOF
```

**Create a Placement Binding ansible-automation-platform-installed to place this policy on all OpenShift managed clusters.**

```bash
cat << EOF >$HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-installed/placementbinding.yaml

---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: ansible-automation-platform-installed
  namespace: acm-policies
placementRef:
  apiGroup: apps.open-cluster-management.io
  kind: PlacementRule
  name: ansible-automation-platform-installed
subjects:
- apiGroup: policy.open-cluster-management.io
  kind: Policy
  name: ansible-automation-platform-installed
EOF
```

**Add, commit and push the files to the repository.**

```bash
cd $HOME/rhacm-configuration
git add -A

git commit -m "Added Ansible Automation Platform Operator installed policy"

git push
```

**Create a policy ansible-automation-platform in namespace acm-policies that creates all the required objects for the Ansible Automation Platform Operator.**

```bash
mkdir -p $HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-instance

cd $HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-instance
```


```bash
cat << EOF >$HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-instance/policy.yaml

---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: ansible-automation-platform-instance
  namespace: acm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: ansible-automation-platform-instance
      spec:
        remediationAction: enforce
        severity: medium
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: automationcontroller.ansible.com/v1beta1
            kind: AutomationController
            metadata:
              labels:
                app.kubernetes.io/component: automationcontroller
                app.kubernetes.io/managed-by: automationcontroller-operator
                app.kubernetes.io/name: ac-tower
                app.kubernetes.io/operator-version: ''
                app.kubernetes.io/part-of: ac-tower
              name: ac-tower
              namespace: ansible-automation-platform
            spec:
              ee_resource_requirements:
                limits:
                cpu: 2000m
                requests:
                cpu: 500m
              create_preload_data: true
              route_tls_termination_mechanism: Edge
              garbage_collect_secrets: false
              loadbalancer_port: 80
              projects_use_existing_claim: _No_
              task_resource_requirements:
                limits:
                cpu: 2000m
                requests:
                cpu: 500m
              image_pull_policy: IfNotPresent
              projects_storage_size: 8Gi
              admin_email: admin@example.com
              task_privileged: false
              projects_storage_class: ocs-storagecluster-ceph-rbd
              projects_storage_access_mode: ReadWriteOnce
              web_resource_requirements:
                limits:
                cpu: 2000m
                requests:
                cpu: 500m
              projects_persistence: true
              replicas: 1
              admin_user: admin
              loadbalancer_protocol: http
              nodeport_port: 30080
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Namespace
            metadata:
              name: ansible-automation-platform
EOF
```

**Create a placement rule named ansible-automation-platform-instance to select all OpenShift clusterswith either label purpose=development or purpose=production.**

```bash
cat << EOF >$HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-instance/placementrule.yaml

---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: ansible-automation-platform-instance
  namespace: acm-policies
spec:
  clusterSelector:
    matchExpressions:
    - key: vendor
      operator: In
      values:
        - OpenShift
    - key: purpose
      operator: In
      values:
        - development
        - production
EOF
```

**Create a Placement Binding ansible-automation-platform-instance to place this policy on all OpenShift managed clusters.**

```bash
cat << EOF >$HOME/rhacm-configuration/rhacm-root/policies/ansible-automation-platform-instance/placementbinding.yaml

---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: ansible-automation-platform-instance
  namespace: acm-policies
placementRef:
  apiGroup: apps.open-cluster-management.io
  kind: PlacementRule
  name: ansible-automation-platform-instance
subjects:
- apiGroup: policy.open-cluster-management.io
  kind: Policy
  name: ansible-automation-platform-instance
EOF
```

**Add, commit and push the files to the repository.**

```bash
cd $HOME/rhacm-configuration
git add -A

git commit -m "Added SAnsible Automation Platform Instance policy"

git push
```



