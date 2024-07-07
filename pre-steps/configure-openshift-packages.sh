#!/bin/bash
#set -e

# Detect RHEL version
if [ -f /etc/os-release ]; then
    # Determine the RHEL version
    RHEL_VERSION=$(rpm -E %{rhel})
fi

# Set VERSION based on RHEL version
if  [ -z $VERSION ];
then
  if [[ "$RHEL_VERSION" == "8" ]]; then
    export  VERSION="stable-4.15"
  elif [[ "$RHEL_VERSION" == "9" || "$RHEL_VERSION" -gt "9" ]]; then
    export VERSION="latest"
  else
    export VERSION="latest"
  fi
fi


function checkForProgramAndInstall() {
    command -v $1 > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        printf '%-72s %-7s\n' $1 "PASSED!";
    else
        if [[ "$ID" == "rhel" || "$ID" == "centos" ]]; then
            sudo yum install -y $1
        elif [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
            sudo apt-get update && sudo apt-get install -y $1
        else
            echo "Unsupported OS. Cannot install $1."
            exit 1
        fi
    fi
}

function download_binaries(){
    checkForProgramAndInstall wget

    if [ "pre-release" == "${1}" ];
    then 
      echo "*******************************"
      echo "Installing pre-release binaries" 
      echo "*******************************"
      URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/pre-release/"
      LATEST_INSTALLER=$(curl -sL  https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/pre-release/  | grep -oE openshift-install-linux-4.[0-9].[0-9]-[0-9].nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}.tar.gz | head -1)
      LATEST_CLI=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/pre-release/  | grep -oE openshift-client-linux-4.[0-9].[0-9]-[0-9].nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}.tar.gz | head -1)
    else
      echo "*******************************"
      echo "Installing ${VERSION} binaries" 
      echo "*******************************"
      URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/"
      LATEST_CLI=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/  | grep -o openshift-client-linux-4.[[:digit:]]\+.[[:digit:]]\+.tar.gz | head -1)
      LATEST_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/  | grep -o openshift-install-linux-4.[[:digit:]]\+.[[:digit:]]\+.tar.gz | head -1)
    fi


    SUDO=''
    if (( $EUID != 0 )); then
        SUDO='sudo'
    fi

    OC_INSTALLER=openshift-install-linux.tar.gz
    echo "*************************"
    echo "Downloading ${LATEST_INSTALLER}"
    echo "*************************"
    sleep 3s
    wget ${URL}${OC_INSTALLER}
    if [ $? -ne 0 ]; then
        echo "Failed to download ${LATEST_INSTALLER}"
        exit 1
    fi
    $SUDO tar zxvf ${OC_INSTALLER} -C /usr/bin
    rm -f ${OC_INSTALLER}
    $SUDO chmod +x /usr/bin/openshift-install
    openshift-install version

    OC_CLI_CLIENT=openshift-client-linux.tar.gz
    echo "********************************"
    echo "Downloading ${LATEST_CLI}"
    echo "********************************"
    sleep 3s
    wget ${URL}${OC_CLI_CLIENT}
    if [ $? -ne 0 ]; then
        echo "Failed to download ${LATEST_CLI}"
        exit 1
    fi
    $SUDO tar zxvf ${OC_CLI_CLIENT} -C /usr/bin
    rm -f ${OC_CLI_CLIENT}
    $SUDO chmod +x /usr/bin/oc
    $SUDO oc version
}

function delete_binaries(){
    SUDO=''
    if (( $EUID != 0 )); then
        SUDO='sudo'
    fi

    echo "*******************************"
    echo "Removing OpenShift binaries"
    echo "*******************************"
    read -p "Are you sure you want to remove OpenShift binaries? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $SUDO rm -rf /usr/bin/oc
        $SUDO rm -rf /usr/bin/kubectl
        $SUDO rm -rf /usr/bin/openshift-install
        $SUDO rm -rf /etc/bash_completion.d/openshift
        $SUDO rm -rf /etc/bash_completion.d/openshift-install
    else
        echo "Aborting."
    fi
}

# Print usage
usage() {
    echo -n "${0} [OPTION]

    Options:
    -i, --install     Install OpenShift latest binaries
    -d, --delete      Remove oc client and openshift-install
    -h, --help        Display this help and exit

    To install OpenShift latest binaries
    ${0}  --install

    To install OpenShift pre-release binaries
    ${0}  --install -v pre-release

    To install specific OpenShift Version
    export VERSION=latest-4.9
    ${0} -i
    "
}

optstring=v
unset options
while (($#)); do
    case $1 in
        -[!-]?*)
            for ((i=1; i < ${#1}; i++)); do
                c=${1:i:1}
                options+=("-$c")
                if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
                    options+=("${1:i+1}")
                    break
                fi
            done
            ;;
        --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
        --) options+=(--endopts) ;;
        *) options+=("$1") ;;
    esac
    shift
done
set -- "${options[@]}"
unset options

while [[ $1 = -?* ]]; do
    case $1 in
        -h|--help) usage >&2; break ;;
        -i|--install) shift; download_binaries $2 ;;
        -d|--delete) shift; delete_binaries;;
        --endopts) shift; break ;;
        *) echo "invalid option: '$1'."; usage >&2; exit 1 ;;
    esac
    shift
done

# Store the remaining part as arguments.
args+=("$@")

if [ -z $1 ]; then
    usage
    exit
fi