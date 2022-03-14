#!/bin/bash
set -e
if [ -z $VERSION ];
then
    export VERSION=latest
fi 

function download_binaries(){

    if [ "pre-release" == ${1} ];
    then 
       echo "*******************************"
       echo "Installing pre-release binaries" 
       echo "*******************************"
       URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/pre-release/"
       LATEST_INSTALLER=$(curl -sL  https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/pre-release/  | grep -oE openshift-install-linux-4.[0-9].[0-9]-[0-9].nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}.tar.gz | head -1
    )
       LATEST_CLI=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/pre-release/  | grep -oE openshift-client-linux-4.[0-9].[0-9]-[0-9].nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}.tar.gz | head -1
    )
    else
       echo "*******************************"
       echo "Installing ${VERSION} binaries" 
       echo "*******************************"
       URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/"
       LATEST_CLI=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/  | grep -o openshift-client-linux-4.[0-9].[0-9].tar.gz | head -1)
       LATEST_INSTALLER=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/  | grep -o openshift-install-linux-4.[0-9].[0-9].tar.gz | head -1)
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
    $SUDO tar zxvf ${OC_CLI_CLIENT} -C /usr/bin
    rm -f ${OC_CLI_CLIENT}
    $SUDO chmod +x /usr/bin/oc
    oc version

    if (( $EUID != 0 )); then
      oc completion bash > openshift
      $SUDO mv openshift /etc/bash_completion.d/
      openshift-install completion bash > openshift-install
      $SUDO mv openshift-install /etc/bash_completion.d/
    else
      oc completion bash > /etc/bash_completion.d/openshift
      openshift-install completion bash > /etc/bash_completion.d/openshift-install
    fi 


    source /etc/bash_completion.d/openshift
    source /etc/bash_completion.d/openshift-install

    echo "*******************************"
    echo "run the following to source the openshift auto complete"
    echo "*******************************" 
    echo "source /etc/bash_completion.d/openshift"
    echo "source /etc/bash_completion.d/openshift-install"
}

function delete_binaries(){
    SUDO=''
    if (( $EUID != 0 )); then
        SUDO='sudo'
    fi

    echo "*******************************"
    echo "Removing OpenShift binaries"
    echo "*******************************" 
    $SUDO rm -rf  /usr/bin/oc
    $SUDO rm -rf /usr/bin/kubectl
    $SUDO rm -rf /usr/bin/openshift-install
    $SUDO rm -rf /etc/bash_completion.d/openshift
    $SUDO rm -rf /etc/bash_completion.d/openshift-install
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
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; break ;;
    -i|--install)  shift; download_binaries $2 ;;
    -d|--delete) shift; delete_binaries;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

if [ -z $1 ];
then
  usage
  exit 1
fi

