#!/bin/bash
# This script sets up a test Vault server in dev mode and creates a token for testing
# DO NOT USE THIS IN PRODUCTION

# Check if Vault is installed
if ! command -v vault &> /dev/null; then
    echo "Error: Vault is not installed. Please install Vault first."
    echo "Visit https://developer.hashicorp.com/vault/downloads for installation instructions."
    exit 1
fi

# Create directory for Vault data
mkdir -p ~/.vault-test

# Start Vault in dev mode in the background
echo "Starting Vault in dev mode..."
vault server -dev -dev-root-token-id="test-token" > ~/.vault-test/vault.log 2>&1 &
VAULT_PID=$!

# Wait for Vault to start
sleep 2

# Check if Vault started successfully
if ! ps -p $VAULT_PID > /dev/null; then
    echo "Error: Failed to start Vault. Check the log at ~/.vault-test/vault.log"
    exit 1
fi

# Set environment variables
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='test-token'

echo "Vault started successfully with PID $VAULT_PID"
echo "Root Token: test-token"
echo ""
echo "Use the following commands to set up your environment:"
echo "export VAULT_ADDR='http://127.0.0.1:8200'"
echo "export VAULT_TOKEN='test-token'"
echo ""
echo "To stop Vault, run: kill $VAULT_PID"
echo ""
echo "Setting up example secrets for OpenShift installation..."

# Create example secrets for AWS
vault kv put secret/aws/pullsecret pull_secret="example-pull-secret"
vault kv put secret/aws/sshkey private_key="example-private-key" public_key="example-public-key"
vault kv put secret/aws/credentials aws_access_key_id="example-access-key" aws_secret_access_key="example-secret-key"

# Create example secrets for ROSA
vault kv put secret/rosa/pullsecret pull_secret="example-pull-secret"
vault kv put secret/rosa/sshkey private_key="example-private-key" public_key="example-public-key"
vault kv put secret/rosa/credentials aws_access_key_id="example-access-key" aws_secret_access_key="example-secret-key"

# Create example secrets for GCP
vault kv put secret/gcp/pullsecret pull_secret="example-pull-secret"
vault kv put secret/gcp/sshkey private_key="example-private-key" public_key="example-public-key"
vault kv put secret/gcp/credentials service_account_key='{"type":"service_account","project_id":"example"}'

# Create example secrets for Azure
vault kv put secret/azure/pullsecret pull_secret="example-pull-secret"
vault kv put secret/azure/sshkey private_key="example-private-key" public_key="example-public-key"
vault kv put secret/azure/credentials client_id="example-client-id" client_secret="example-client-secret" tenant_id="example-tenant-id" subscription_id="example-subscription-id"

# Create example secrets for ARO
vault kv put secret/aro/pullsecret pull_secret="example-pull-secret"
vault kv put secret/aro/sshkey private_key="example-private-key" public_key="example-public-key"
vault kv put secret/aro/credentials client_id="example-client-id" client_secret="example-client-secret" tenant_id="example-tenant-id" subscription_id="example-subscription-id"

echo "Example secrets created successfully."
echo ""
echo "IMPORTANT: This is a test setup with dummy values. Do not use in production."
echo "Use this token as the VAULT_TOKEN GitHub repository secret for testing:"
echo "test-token"
