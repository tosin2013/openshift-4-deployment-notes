#!/bin/bash
set -eo pipefail # Exit immediately if a command exits with a non-zero status.

# This script stores secrets (pull secret, SSH keys, AWS credentials) into files
# and sets up the SSH agent. It expects necessary secret content and paths
# to be provided as environment variables.

# Expected environment variables:
# - PULL_SECRET_CONTENT
# - SSH_PRIVATE_KEY_CONTENT
# - SSH_PUBLIC_KEY_CONTENT
# - AWS_ACCESS_KEY_ID_CONTENT
# - AWS_SECRET_ACCESS_KEY_CONTENT
# - AWS_REGION_FOR_CRED_FILE
# - INSTALL_DIR_PATH
# - ARTIFACTS_DIR_PATH (for handle_error sourcing and logging)
# - CLUSTER_NAME (for handle_error context)

# Source error handler if available and not already sourced
# The main workflow should have already sourced and exported handle_error.
if [ -n "${ARTIFACTS_DIR_PATH}" ] && [ -f "${ARTIFACTS_DIR_PATH}/error_handler.sh" ] && ! command -v handle_error &> /dev/null; then
  echo "Sourcing error_handler.sh from aws/store-secrets.sh"
  source "${ARTIFACTS_DIR_PATH}/error_handler.sh"
elif ! command -v handle_error &> /dev/null; then
  echo "Warning (store-secrets.sh): handle_error function not found. Using a basic fallback."
  # Define a fallback simple error handler
  function handle_error() {
    echo "Fallback Error Handler (store-secrets.sh): Exit Code $1, Message: $2, Step: $3"
    exit "$1"
  }
fi

echo "Starting to store secrets securely via aws/store-secrets.sh..."

# Validate required environment variables
if [ -z "${PULL_SECRET_CONTENT}" ]; then handle_error 1 "PULL_SECRET_CONTENT is not set" "Store Secrets Script"; fi
if [ -z "${SSH_PRIVATE_KEY_CONTENT}" ]; then handle_error 1 "SSH_PRIVATE_KEY_CONTENT is not set" "Store Secrets Script"; fi
if [ -z "${SSH_PUBLIC_KEY_CONTENT}" ]; then handle_error 1 "SSH_PUBLIC_KEY_CONTENT is not set" "Store Secrets Script"; fi
if [ -z "${AWS_ACCESS_KEY_ID_CONTENT}" ]; then handle_error 1 "AWS_ACCESS_KEY_ID_CONTENT is not set" "Store Secrets Script"; fi
if [ -z "${AWS_SECRET_ACCESS_KEY_CONTENT}" ]; then handle_error 1 "AWS_SECRET_ACCESS_KEY_CONTENT is not set" "Store Secrets Script"; fi
if [ -z "${AWS_REGION_FOR_CRED_FILE}" ]; then handle_error 1 "AWS_REGION_FOR_CRED_FILE is not set" "Store Secrets Script"; fi
if [ -z "${INSTALL_DIR_PATH}" ]; then handle_error 1 "INSTALL_DIR_PATH is not set" "Store Secrets Script"; fi

# Store pull secret
echo "Storing pull secret to ${INSTALL_DIR_PATH}/pull-secret.json"
echo "${PULL_SECRET_CONTENT}" > "${INSTALL_DIR_PATH}/pull-secret.json"
chmod 600 "${INSTALL_DIR_PATH}/pull-secret.json"

# Store SSH keys
echo "Storing SSH keys in $HOME/.ssh/"
mkdir -p "$HOME/.ssh"
echo "${SSH_PRIVATE_KEY_CONTENT}" > "$HOME/.ssh/cluster-key"
echo "${SSH_PUBLIC_KEY_CONTENT}" > "$HOME/.ssh/cluster-key.pub"
chmod 600 "$HOME/.ssh/cluster-key"
chmod 644 "$HOME/.ssh/cluster-key.pub"

# Set up SSH agent
echo "Setting up SSH agent and adding cluster-key..."
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/cluster-key"

# Store AWS credentials
echo "Storing AWS credentials in $HOME/.aws/credentials"
mkdir -p "$HOME/.aws"
cat > "$HOME/.aws/credentials" << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID_CONTENT}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY_CONTENT}
region = ${AWS_REGION_FOR_CRED_FILE}
EOF
chmod 600 "$HOME/.aws/credentials"

# Verify files were created successfully
if [ ! -f "${INSTALL_DIR_PATH}/pull-secret.json" ]; then
  handle_error 1 "Failed to create pull-secret.json" "Store Secrets Script"
fi
if [ ! -f "$HOME/.ssh/cluster-key" ]; then
  handle_error 1 "Failed to create $HOME/.ssh/cluster-key" "Store Secrets Script"
fi
if [ ! -f "$HOME/.aws/credentials" ]; then
  handle_error 1 "Failed to create $HOME/.aws/credentials" "Store Secrets Script"
fi

echo "Secrets stored securely in the environment and files by aws/store-secrets.sh."

