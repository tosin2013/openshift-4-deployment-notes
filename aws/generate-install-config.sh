#!/bin/bash
set -eo pipefail

# This script generates the install-config.yaml for OpenShift on AWS.
# It expects the following environment variables to be set:
# - INSTALL_DIR
# - BASE_DOMAIN
# - CLUSTER_NAME
# - AWS_REGION
# - EXISTING_VPC_ID (optional)
# - EXISTING_SUBNET_IDS (optional, comma-separated)
# - COMPUTE_INSTANCE_TYPE
# - COMPUTE_NODES
# - CONTROL_PLANE_INSTANCE_TYPE
# - SINGLE_AZ_DEPLOYMENT (boolean string "true" or "false")
# - PULL_SECRET_CONTENT_RAW (raw pull secret JSON string)
# - SSH_KEY_CONTENT_RAW (raw public SSH key string)
# - ARTIFACTS_DIR (for backing up the install-config.yaml)

echo "Generating install-config.yaml in ${INSTALL_DIR}..."

# Validate required environment variables
if [ -z "${INSTALL_DIR}" ] || \
   [ -z "${BASE_DOMAIN}" ] || \
   [ -z "${CLUSTER_NAME}" ] || \
   [ -z "${AWS_REGION}" ] || \
   [ -z "${COMPUTE_INSTANCE_TYPE}" ] || \
   [ -z "${COMPUTE_NODES}" ] || \
   [ -z "${CONTROL_PLANE_INSTANCE_TYPE}" ] || \
   [ -z "${SINGLE_AZ_DEPLOYMENT}" ] || \
   [ -z "${PULL_SECRET_CONTENT_RAW}" ] || \
   [ -z "${ARTIFACTS_DIR}" ] || \
   [ -z "${SSH_KEY_CONTENT_RAW}" ]; then
  echo "Error: One or more required environment variables for install-config generation are not set."
  echo "Required: INSTALL_DIR, BASE_DOMAIN, CLUSTER_NAME, AWS_REGION, COMPUTE_INSTANCE_TYPE, COMPUTE_NODES, CONTROL_PLANE_INSTANCE_TYPE, SINGLE_AZ_DEPLOYMENT, PULL_SECRET_CONTENT_RAW, SSH_KEY_CONTENT_RAW, ARTIFACTS_DIR"
  exit 1
fi

mkdir -p "${INSTALL_DIR}"
mkdir -p "${ARTIFACTS_DIR}" # Ensure artifacts directory exists

# Prepare pull secret and ssh key for embedding
# For pullSecret, it's typically a JSON string. Ensuring it's compact and then indenting.
PULL_SECRET_CONTENT_COMPACT=$(echo "${PULL_SECRET_CONTENT_RAW}" | jq -c .)
INDENTED_PULL_SECRET=$(echo "${PULL_SECRET_CONTENT_COMPACT}" | sed 's/^/    /') # 4 spaces for YAML block scalar

# For sshKey, it's usually a single line public key. Indent it.
INDENTED_SSH_KEY=$(echo "${SSH_KEY_CONTENT_RAW}" | sed 's/^/    /') # 4 spaces for YAML block scalar

# Start install-config.yaml
cat > "${INSTALL_DIR}/install-config.yaml" <<EOF
apiVersion: v1
baseDomain: ${BASE_DOMAIN}
metadata:
  name: ${CLUSTER_NAME}
platform:
  aws:
    region: ${AWS_REGION}
EOF

# Conditionally add userTags and vpcID if EXISTING_VPC_ID is set
if [ -n "${EXISTING_VPC_ID}" ]; then
  cat >> "${INSTALL_DIR}/install-config.yaml" <<EOF_VPC
    userTags:
      Name: ${CLUSTER_NAME}
    vpcID: ${EXISTING_VPC_ID}
EOF_VPC
fi

# Conditionally add subnets if EXISTING_SUBNET_IDS is set
if [ -n "${EXISTING_SUBNET_IDS}" ]; then
  echo "    subnets:" >> "${INSTALL_DIR}/install-config.yaml"
  IFS=',' read -ra SUBNET_ARRAY <<< "${EXISTING_SUBNET_IDS}"
  for subnet_id in "${SUBNET_ARRAY[@]}"; do
    trimmed_subnet_id=$(echo "$subnet_id" | xargs) # Trim whitespace
    echo "      - \\"${trimmed_subnet_id}\\"" >> "${INSTALL_DIR}/install-config.yaml"
  done
fi

# Add compute, controlPlane, networking, pullSecret, sshKey, fips, publish
cat >> "${INSTALL_DIR}/install-config.yaml" <<EOF_MAIN
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    aws:
      type: ${COMPUTE_INSTANCE_TYPE}
  replicas: ${COMPUTE_NODES}
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    aws:
      type: ${CONTROL_PLANE_INSTANCE_TYPE}
  replicas: 3 # Note: Consider SINGLE_AZ_DEPLOYMENT here if implemented
networking:
  networkType: OVNKubernetes # Assuming OVNKubernetes, make this configurable if needed via env var
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  serviceNetwork:
  - 172.30.0.0/16
pullSecret: |
${INDENTED_PULL_SECRET}
sshKey: |
${INDENTED_SSH_KEY}
fips: false # Make this configurable if needed via env var
publish: External # Make this configurable if needed via env var
EOF_MAIN

# Add a comment about single_az_deployment if it's set to true
if [ "${SINGLE_AZ_DEPLOYMENT}" = "true" ]; then
  cat >> "${INSTALL_DIR}/install-config.yaml" <<EOF_AZ_COMMENT

# Warning: input single_az_deployment=true but this install-config.yaml may not fully
# reflect a single-AZ deployment (e.g. controlPlane replicas are still 3).
# Further customization might be needed for a true single-AZ setup.
EOF_AZ_COMMENT
fi

echo "install-config.yaml generated successfully at ${INSTALL_DIR}/install-config.yaml"

# Backup the install config
cp "${INSTALL_DIR}/install-config.yaml" "${ARTIFACTS_DIR}/install-config.yaml"
echo "Backed up install-config.yaml to ${ARTIFACTS_DIR}/install-config.yaml"

echo "DEBUG: final install-config.yaml content:"
cat "${INSTALL_DIR}/install-config.yaml"
