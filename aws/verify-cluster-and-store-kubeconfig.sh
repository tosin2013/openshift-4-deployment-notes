#!/bin/bash
set -eo pipefail # Exit on error, treat unset variables as an error, and propagate pipeline failures.

# This script verifies the OpenShift cluster and stores the kubeconfig in HashiCorp Vault.
# It expects the following environment variables to be set:
# - INSTALL_DIR: The directory where installation files are stored (e.g., /tmp/cluster)
# - ARTIFACTS_DIR: The directory for storing logs and artifacts (e.g., /tmp/artifacts)
# - VAULT_SERVICE: The type of Vault service being used (e.g., 'self-hosted', 'hcp-vault-dedicated', 'hcp-vault-secrets')
# - CLUSTER_NAME: The name of the OpenShift cluster.
# - KUBECONFIG_FILEPATH: Path to the kubeconfig file.
#
# For 'self-hosted' or 'hcp-vault-dedicated' Vault services, it also expects:
# - VAULT_ADDR: The URL of the Vault server.
# - VAULT_TOKEN: The token for authenticating with Vault.
# - VAULT_NAMESPACE: (Optional) The Vault namespace.

echo "--- Starting Cluster Verification and Kubeconfig Storage ---"
echo "INSTALL_DIR: '${INSTALL_DIR}'"
echo "ARTIFACTS_DIR: '${ARTIFACTS_DIR}'"
echo "VAULT_SERVICE: '${VAULT_SERVICE}'"
echo "CLUSTER_NAME: '${CLUSTER_NAME}'"
echo "KUBECONFIG_FILEPATH: '${KUBECONFIG_FILEPATH}'"

# Validate required environment variables
if [ -z "${INSTALL_DIR}" ]; then echo "Error: INSTALL_DIR is not set."; exit 1; fi
if [ -z "${ARTIFACTS_DIR}" ]; then echo "Error: ARTIFACTS_DIR is not set."; exit 1; fi
if [ -z "${VAULT_SERVICE}" ]; then echo "Error: VAULT_SERVICE is not set."; exit 1; fi
if [ -z "${CLUSTER_NAME}" ]; then echo "Error: CLUSTER_NAME is not set."; exit 1; fi
if [ -z "${KUBECONFIG_FILEPATH}" ]; then echo "Error: KUBECONFIG_FILEPATH is not set."; exit 1; fi

if [ ! -f "${KUBECONFIG_FILEPATH}" ]; then
  echo "Error: Kubeconfig file not found at '${KUBECONFIG_FILEPATH}'."
  echo "This usually means the OpenShift installation failed or did not produce a kubeconfig file."
  exit 1
fi

export KUBECONFIG="${KUBECONFIG_FILEPATH}"

echo "Verifying cluster API accessibility..."
MAX_RETRIES=12 # 12 retries * 30 seconds = 6 minutes
RETRY_INTERVAL=30
API_ACCESSIBLE=false
for i in $(seq 1 ${MAX_RETRIES}); do
  if oc cluster-info &>/dev/null; then
    echo "Cluster API is accessible."
    API_ACCESSIBLE=true
    break
  fi
  echo "Attempt ${i}/${MAX_RETRIES}: Waiting for cluster API to be accessible (next check in ${RETRY_INTERVAL}s)..."
  sleep ${RETRY_INTERVAL}
done

if [ "${API_ACCESSIBLE}" = "false" ]; then
  echo "Error: Cluster API was not accessible after ${MAX_RETRIES} retries."
  oc cluster-info # Print details for debugging
  exit 1
fi

echo "Checking node status..."
NODES_ACCESSIBLE=false
for i in $(seq 1 ${MAX_RETRIES}); do
  if oc get nodes &>/dev/null; then
    NODE_OUTPUT=$(oc get nodes -o wide) # Capture output for logging
    echo "Node status is accessible."
    echo "${NODE_OUTPUT}" # Log node status
    NODES_ACCESSIBLE=true
    break
  fi
  echo "Attempt ${i}/${MAX_RETRIES}: Waiting for node status to be accessible (next check in ${RETRY_INTERVAL}s)..."
  sleep ${RETRY_INTERVAL}
done

if [ "${NODES_ACCESSIBLE}" = "false" ]; then
  echo "Error: Node status was not accessible after ${MAX_RETRIES} retries."
  oc get nodes # Print details for debugging
  exit 1
fi

# Function to store kubeconfig in Vault
store_kubeconfig_in_vault() {
  echo "--- store_kubeconfig_in_vault execution ---"
  echo "VAULT_ADDR: '${VAULT_ADDR}'"
  echo "VAULT_TOKEN: Present (masked for security)"
  echo "VAULT_NAMESPACE: '${VAULT_NAMESPACE:-not set, using Vault default}'"
  echo "CLUSTER_NAME: '${CLUSTER_NAME}'"
  echo "KUBECONFIG_FILEPATH: '${KUBECONFIG_FILEPATH}'"
  echo "-------------------------------------------"

  if [ -z "${VAULT_ADDR}" ]; then echo "Error (store_kubeconfig_in_vault): VAULT_ADDR is not set."; return 1; fi
  if [ -z "${VAULT_TOKEN}" ]; then echo "Error (store_kubeconfig_in_vault): VAULT_TOKEN is not set."; return 1; fi

  echo "Storing kubeconfig from '${KUBECONFIG_FILEPATH}' for cluster '${CLUSTER_NAME}' in Vault."
  echo "Target Vault Details - Addr: '${VAULT_ADDR}', Namespace: '${VAULT_NAMESPACE:-not set, using Vault default}'"

  if vault kv put "openshift/aws/${CLUSTER_NAME}/kubeconfig" value=@"${KUBECONFIG_FILEPATH}"; then
    echo "Kubeconfig stored successfully in Vault at path: openshift/aws/${CLUSTER_NAME}/kubeconfig"
  else
    echo "Warning: Failed to store kubeconfig in Vault. vault kv put command failed."
    return 1 # Indicate failure
  fi
  return 0
}

# Store kubeconfig in Vault (conditionally)
if [ "${VAULT_SERVICE}" != "hcp-vault-secrets" ]; then
  echo "Attempting to store kubeconfig in Vault (${VAULT_SERVICE})..."
  if [ -z "${VAULT_ADDR}" ]; then
    echo "Critical Error (verify-cluster-and-store-kubeconfig.sh): VAULT_ADDR is not set. Cannot store kubeconfig in Vault."
    echo "Warning: Kubeconfig will not be stored in Vault."
  elif [ -z "${VAULT_TOKEN}" ]; then
    echo "Critical Error (verify-cluster-and-store-kubeconfig.sh): VAULT_TOKEN is not set. Cannot store kubeconfig in Vault."
    echo "Warning: Kubeconfig will not be stored in Vault."
  else
    if ! store_kubeconfig_in_vault; then
      echo "Warning: Failed to store kubeconfig in Vault. The cluster is still accessible using the kubeconfig file: ${KUBECONFIG_FILEPATH}"
      echo "The kubeconfig is also available in the run artifacts at ${ARTIFACTS_DIR}/auth/kubeconfig (if copied there by installer)."
    fi
  fi
else
  echo "Kubeconfig storage in Vault is skipped for HCP Vault Secrets service."
  echo "Kubeconfig is available at: ${KUBECONFIG_FILEPATH}"
  echo "It should also be available in the run artifacts (e.g., ${ARTIFACTS_DIR}/auth/kubeconfig if the installer copied it there)."
fi

echo "--- Cluster Verification and Kubeconfig Storage Completed Successfully ---"
