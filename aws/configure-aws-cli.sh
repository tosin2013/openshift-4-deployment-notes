#!/bin/bash
#set -xe 


# Print usage
usage() {
  echo -n "${0} [OPTION]

 Options:
  -i, --install     Install awscli latest binaries
  -d, --delete      Remove awscli
  -h, --help        Display this help and exit

  USAGE: $0 -i aws_access_key_id aws_secret_access_key aws_region
"

}


if [ "$EUID" -ne 0 ]
  then 
  RUN_SUDO="sudo"
fi

function install_aws_cli(){
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip

  ${RUN_SUDO} ./aws/install

  aws --version || exit 1

  if [ "$EUID" -ne 0 ]
  then
    rm -rf ${HOME}/awscli-bundle ${HOME}/awscli-bundle.zip 
  else
    rm -rf /root/awscli-bundle /root/awscli-bundle.zip 
  fi

  export AWSKEYID=${1}
  export AWSSECRETKEY=${2}
  export REGION=${3}

  mkdir -p $HOME/.aws
  cat  >$HOME/.aws/credentials<<EOF
[default]
aws_access_key_id = ${AWSKEYID}
aws_secret_access_key = ${AWSSECRETKEY}
region = ${REGION}
EOF

  cat $HOME/.aws/credentials

  aws sts get-caller-identity || exit $?

}

function delete_aws_cli(){
    echo "*******************************"
    echo "        Removing aws cli     "
    echo "*******************************" 
  ${RUN_SUDO} rm -rf /usr/local/bin/aws
  ${RUN_SUDO} rm -rf /usr/local/aws-cli/v2/

  if [ "$EUID" -ne 0 ]
  then
    rm -rf $(find $HOME -name awscliv2.zip)
    if  [ -d $(pwd)/aws ];
    then 
      rm -rf $(pwd)/aws
    fi
  else
    rm -rf /root/awscli-bundle /root/awscli-bundle.zip 
    rm -rf /root/awscliv2.zip
    rm -rf /root/aws
  fi

  exit 0
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
    -i|--install)  shift; install_aws_cli $1 $2 $3;;
    -d|--delete) shift; delete_aws_cli;;
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