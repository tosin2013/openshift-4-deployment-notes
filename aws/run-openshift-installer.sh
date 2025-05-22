#!/bin/bash
set -eo pipefail

# This script runs the OpenShift installer.
# Expected environment variables:
# - INSTALL_DIR: Directory where installation files are located and where OpenShift will be installed.
# - ARTIFACTS_DIR: Directory to store logs and installation artifacts.
# - CLUSTER_NAME: Name of the cluster (used by handle_error via sourced error_handler.sh).
# The handle_error function is expected to be available from the main workflow context.

echo "Running OpenShift installer in ${INSTALL_DIR}..."

if [ -z "${INSTALL_DIR}" ] || [ -z "${ARTIFACTS_DIR}" ]; then
  echo "Error (run-openshift-installer.sh): INSTALL_DIR and ARTIFACTS_DIR environment variables must be set."
  handle_error 1 "INSTALL_DIR or ARTIFACTS_DIR not set for run-openshift-installer.sh" "Run OpenShift Installer Script"
  exit 1 # Should be redundant if handle_error exits
fi

cd "${INSTALL_DIR}" || {
  handle_error $? "Failed to change directory to ${INSTALL_DIR}" "Run OpenShift Installer Script"
  exit 1 # Redundant
}

echo "Executing: openshift-install create cluster --dir=. --log-level=debug"
echo "Installer output will be logged to ${ARTIFACTS_DIR}/install.log"

# Run the installer, redirecting its output to install.log
openshift-install create cluster --dir=. --log-level=debug &> "${ARTIFACTS_DIR}/install.log" || {
  local exit_code=$?
  echo "OpenShift installation command failed with exit code ${exit_code}." | tee -a "${ARTIFACTS_DIR}/installation.log" # Also log to main installation log
  echo "See full installer log at ${ARTIFACTS_DIR}/install.log." | tee -a "${ARTIFACTS_DIR}/installation.log"
  handle_error ${exit_code} "OpenShift installation failed during 'create cluster'. Check ${ARTIFACTS_DIR}/install.log." "Run OpenShift Installer Script"
  exit ${exit_code} # Redundant
}

echo "OpenShift installer command completed successfully." | tee -a "${ARTIFACTS_DIR}/installation.log"
echo "Verifying kubeconfig presence..." | tee -a "${ARTIFACTS_DIR}/installation.log"

if [ ! -f "${INSTALL_DIR}/auth/kubeconfig" ]; then
  echo "Error: Kubeconfig not found at ${INSTALL_DIR}/auth/kubeconfig after installation." | tee -a "${ARTIFACTS_DIR}/installation.log"
  handle_error 1 "Kubeconfig not found after installation" "Run OpenShift Installer Script"
  exit 1 # Redundant
fi

echo "Kubeconfig found at ${INSTALL_DIR}/auth/kubeconfig." | tee -a "${ARTIFACTS_DIR}/installation.log"
echo "OpenShift cluster installation script (run-openshift-installer.sh) completed successfully." | tee -a "${ARTIFACTS_DIR}/installation.log"
