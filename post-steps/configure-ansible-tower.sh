#!/bin/bash 
#set -x
#set -e
# Print usage
function usage() {
  echo -n "${0} [OPTION]
 Options:
  -d      Openshift API URL
  -n      Openshift Username
  -p      Openshift Password
  -h      Display this help and exit
  -u      Uninstall coffeeshop 
  To deploy ansible tower to OpenShift
  ${0}  -d https://api.ocp4.example.com:6443 -n admin -p 123456789 
  To delete ansible tower from OpenShift
  ${0}  -d https://api.ocp4.example.com:6443 -n admin -p 123456789 -u true
"
}

function check-install-dir(){
    if [ ! -d ~/ansible-tower-openshift-setup-3.[0-9].[0-9]-* ];
    then 
        cd ~
        curl -OL https://releases.ansible.com/ansible-tower/setup_openshift/ansible-tower-openshift-setup-latest.tar.gz
        tar -xzf ansible-tower-openshift-setup-latest.tar.gz
    fi
}

function configure-tower(){
    if [ -d ~/ansible-tower-openshift-setup-3.[0-9].[0-9]-* ];
    then 
        cd ~/ansible-tower-openshift-setup-3.[0-9].[0-9]-* 
        cat roles/kubernetes/tasks/openshift_auth.yml | awk '{sub(/false/,"true")}1' | tee roles/kubernetes/tasks/openshift_auth.yml
        sed -i 's/task_cpu_request:.*/task_cpu_request: 500/g' roles/kubernetes/defaults/main.yml
        sed -i 's/task_mem_request:.*/task_mem_request: 1/g' roles/kubernetes/defaults/main.yml
        sed -i 's/redis_mem_request:.*/redis_mem_request: 1/g' roles/kubernetes/defaults/main.yml
        oc login ${1} -u=${2} -p=${3}
        oc new-project tower
        cat >/tmp/postgres-nfs-pvc.yml<<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgresql
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF
        cat /tmp/postgres-nfs-pvc.yml
        oc project tower
        oc create -f /tmp/postgres-nfs-pvc.yml
    fi
}

function deploy-to-openshift(){
    if [ -d ~/ansible-tower-openshift-setup-3.[0-9].[0-9]-* ];
    then 
        cd ~/ansible-tower-openshift-setup-3.[0-9].[0-9]-* 
        ADMIN_PASSWORD=$(openssl rand -base64 12)
        PG_PASSWORD=$(openssl rand -base64 12)
        RABBITMQ_PASSWORD=$(openssl rand -base64 12)
        oc login ${1} -u=${2} -p=${3}
        ./setup_openshift.sh -e openshift_host=${1} -e openshift_project=tower -e openshift_user=${2} -e openshift_password=${3} -e admin_password=${ADMIN_PASSWORD} -e secret_key=mysecret -e pg_username=admin -e pg_password=${PG_PASSWORD} -e rabbitmq_password=${RABBITMQ_PASSWORD} -e rabbitmq_erlang_cookie=rabbiterlangpwd -e openshift_pg_pvc_name=postgresql || exit $?
        TOWER_ENDPOINT="https://$(oc get routes -n tower | grep tower | awk '{print $2}')"
        cat >~/tower-login-info<<EOF
        OPENSHIFT CLUSTER: ${1}
        TOWER CONSOLE: ${TOWER_ENDPOINT}
        TOWER ADMIN NAME: admin
        TOWER ADMIN PASSWORD: ${ADMIN_PASSWORD}
        POSTGRES PASSWORD: ${PG_PASSWORD}
        RABBITMQ PASSWORD: ${RABBITMQ_PASSWORD}
EOF
        echo "Use the URL ${TOWER_ENDPOINT} to login to tower"
        echo "Your user name and password is found in the file cat ~/tower-login-info"
    fi
}

function remove-tower(){
    oc login ${1} -u=${2} -p=${3}
    if [  -f /tmp/postgres-nfs-pvc.yml ];
    then 
        oc project tower
        oc delete all  --selector app=ansible-tower
        oc delete all  --selector app=postgresql-persistent
        oc delete -f /tmp/postgres-nfs-pvc.yml
        rm  /tmp/postgres-nfs-pvc.yml 
        rm ~/tower-login-info
    fi 
    oc delete project tower
}




if [ -z "$1" ];
then
  usage
  exit 1
fi

while getopts ":d:n:p:h:u:" arg; do
  case $arg in
    h) export  HELP=True;;
    d) export  OPENSHIFT_API_URL=$OPTARG;;
    n) export  OPENSHIFT_USERNAME=$OPTARG;;
    p) export  OCP_PASSWORD=$OPTARG;;
    u) export  DESTROY=$OPTARG;;
  esac
done

if [ -z $DESTROY ];
then 
    echo "OPENSHIFT_API_URL: $OPENSHIFT_API_URL OPENSHIFT_USERNAME: $OPENSHIFT_USERNAME OCP_PASSWORD $OCP_PASSWORD"
    check-install-dir 
    configure-tower $OPENSHIFT_API_URL $OPENSHIFT_USERNAME $OCP_PASSWORD
    deploy-to-openshift $OPENSHIFT_API_URL $OPENSHIFT_USERNAME $OCP_PASSWORD
else 
    remove-tower $OPENSHIFT_API_URL $OPENSHIFT_USERNAME $OCP_PASSWORD
fi 