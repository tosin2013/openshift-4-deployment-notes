#!/bin/bash
# This script helps set up and configure HashiCorp Cloud Platform (HCP) Vault
# for use with OpenShift installation workflows

# Set default values
HCP_REGION="us-west-2"
SECRETS_PATH_PREFIX=""
EXAMPLE_SECRETS=false
VERBOSE=false

# Print usage
function usage() {
  echo -n "
Usage: $0 [OPTIONS]

This script helps set up and configure HashiCorp Cloud Platform (HCP) Vault
for use with OpenShift installation workflows.

Options:
  -o, --organization     HCP organization name (required)
  -p, --project          HCP project name (required)
  -c, --cluster          HCP Vault cluster name (required)
  -r, --region           HCP region (default: us-west-2)
  -t, --token            HCP Vault token (required)
  -s, --secrets-path     Path prefix for secrets (default: none)
  -e, --example-secrets  Create example secrets (default: false)
  -v, --verbose          Enable verbose output
  -h, --help             Display this help message

Example:
  $0 --organization myorg --project myproject --cluster myvault --token hvs.example123
"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -o|--organization)
      HCP_ORGANIZATION="$2"
      shift
      shift
      ;;
    -p|--project)
      HCP_PROJECT="$2"
      shift
      shift
      ;;
    -c|--cluster)
      HCP_VAULT_CLUSTER="$2"
      shift
      shift
      ;;
    -r|--region)
      HCP_REGION="$2"
      shift
      shift
      ;;
    -t|--token)
      HCP_VAULT_TOKEN="$2"
      shift
      shift
      ;;
    -s|--secrets-path)
      SECRETS_PATH_PREFIX="$2"
      shift
      shift
      ;;
    -e|--example-secrets)
      EXAMPLE_SECRETS=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Check required parameters
if [ -z "$HCP_ORGANIZATION" ] || [ -z "$HCP_PROJECT" ] || [ -z "$HCP_VAULT_CLUSTER" ] || [ -z "$HCP_VAULT_TOKEN" ]; then
  echo "Error: Missing required parameters."
  usage
  exit 1
fi

# Check if Vault CLI is installed
if ! command -v vault &> /dev/null; then
  echo "Error: Vault CLI is not installed. Please install Vault first."
  echo "Visit https://developer.hashicorp.com/vault/downloads for installation instructions."
  exit 1
fi

# Construct HCP Vault URL
HCP_VAULT_URL="https://${HCP_VAULT_CLUSTER}.vault.${HCP_REGION}.hashicorp.cloud:8200"

# Set environment variables
export VAULT_ADDR="${HCP_VAULT_URL}"
export VAULT_TOKEN="${HCP_VAULT_TOKEN}"
export VAULT_NAMESPACE="admin"

# Function to log verbose messages
function log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "$1"
  fi
}

# Test connection to HCP Vault
echo "Testing connection to HCP Vault at ${HCP_VAULT_URL}..."
if ! vault status &> /dev/null; then
  echo "Error: Failed to connect to HCP Vault. Please check your credentials and try again."
  exit 1
fi

echo "Successfully connected to HCP Vault!"
echo ""
echo "HCP Vault Information:"
echo "Organization: ${HCP_ORGANIZATION}"
echo "Project: ${HCP_PROJECT}"
echo "Cluster: ${HCP_VAULT_CLUSTER}"
echo "Region: ${HCP_REGION}"
echo "URL: ${HCP_VAULT_URL}"
echo ""

# Set up KV secrets engine for each platform
echo "Setting up KV secrets engines..."

# Function to enable KV secrets engine
function enable_kv_engine() {
  local path=$1
  local full_path="${SECRETS_PATH_PREFIX}${path}"
  
  log_verbose "Checking if KV secrets engine is enabled at ${full_path}..."
  
  # Check if the secrets engine is already enabled
  if vault secrets list | grep -q "^${full_path}/"; then
    log_verbose "KV secrets engine already enabled at ${full_path}"
  else
    echo "Enabling KV secrets engine at ${full_path}..."
    vault secrets enable -version=2 -path="${full_path}" kv || {
      echo "Error: Failed to enable KV secrets engine at ${full_path}"
      return 1
    }
    echo "KV secrets engine enabled at ${full_path}"
  fi
  
  return 0
}

# Enable KV secrets engines for each platform
platforms=("aws" "rosa" "gcp" "azure" "aro" "openshift")
for platform in "${platforms[@]}"; do
  enable_kv_engine "${platform}" || exit 1
done

echo "KV secrets engines set up successfully!"
echo ""

# Create example secrets if requested
if [ "$EXAMPLE_SECRETS" = true ]; then
  echo "Creating example secrets..."
  
  # Function to create example secrets
  function create_example_secrets() {
    local platform=$1
    local full_path="${SECRETS_PATH_PREFIX}${platform}"
    
    echo "Creating example secrets for ${platform}..."
    
    # Create pull secret
    vault kv put "${full_path}/pullsecret" pull_secret="example-pull-secret" || {
      echo "Error: Failed to create pull secret for ${platform}"
      return 1
    }
    
    # Create SSH key
    vault kv put "${full_path}/sshkey" private_key="example-private-key" public_key="example-public-key" || {
      echo "Error: Failed to create SSH key for ${platform}"
      return 1
    }
    
    # Create platform-specific credentials
    case $platform in
      aws|rosa)
        vault kv put "${full_path}/credentials" aws_access_key_id="example-access-key" aws_secret_access_key="example-secret-key" || {
          echo "Error: Failed to create credentials for ${platform}"
          return 1
        }
        ;;
      gcp)
        vault kv put "${full_path}/credentials" service_account_key='{"type":"service_account","project_id":"example"}' || {
          echo "Error: Failed to create credentials for ${platform}"
          return 1
        }
        ;;
      azure|aro)
        vault kv put "${full_path}/credentials" client_id="example-client-id" client_secret="example-client-secret" tenant_id="example-tenant-id" subscription_id="example-subscription-id" || {
          echo "Error: Failed to create credentials for ${platform}"
          return 1
        }
        ;;
    esac
    
    return 0
  }
  
  # Create example secrets for each platform (except openshift)
  for platform in "aws" "rosa" "gcp" "azure" "aro"; do
    create_example_secrets "${platform}" || exit 1
  done
  
  echo "Example secrets created successfully!"
  echo ""
  echo "IMPORTANT: These are example secrets with dummy values. Replace them with real values before using in production."
  echo ""
fi

# Create GitHub Actions policy
echo "Creating GitHub Actions policy..."

# Create policy file
cat > github-actions-policy.hcl << EOF
# Allow reading platform secrets
path "${SECRETS_PATH_PREFIX}aws/*" {
  capabilities = ["read"]
}

path "${SECRETS_PATH_PREFIX}rosa/*" {
  capabilities = ["read"]
}

path "${SECRETS_PATH_PREFIX}gcp/*" {
  capabilities = ["read"]
}

path "${SECRETS_PATH_PREFIX}azure/*" {
  capabilities = ["read"]
}

path "${SECRETS_PATH_PREFIX}aro/*" {
  capabilities = ["read"]
}

# Allow reading and writing kubeconfig
path "${SECRETS_PATH_PREFIX}openshift/*" {
  capabilities = ["read", "create", "update"]
}
EOF

# Create policy in Vault
vault policy write github-actions github-actions-policy.hcl || {
  echo "Error: Failed to create GitHub Actions policy"
  exit 1
}

echo "GitHub Actions policy created successfully!"
echo ""

# Print setup instructions
echo "HCP Vault Setup Complete!"
echo ""
echo "Use the following GitHub repository secrets for your workflows:"
echo "HCP_ORGANIZATION: ${HCP_ORGANIZATION}"
echo "HCP_PROJECT: ${HCP_PROJECT}"
echo "HCP_VAULT_CLUSTER: ${HCP_VAULT_CLUSTER}"
echo "HCP_VAULT_REGION: ${HCP_REGION}"
echo "HCP_VAULT_TOKEN: ${HCP_VAULT_TOKEN}"
echo ""
echo "To use the Vault CLI with this HCP Vault instance, run the following commands:"
echo "export VAULT_ADDR='${HCP_VAULT_URL}'"
echo "export VAULT_TOKEN='${HCP_VAULT_TOKEN}'"
echo "export VAULT_NAMESPACE='admin'"
echo ""
echo "For more information on HCP Vault, visit: https://developer.hashicorp.com/hcp/docs/vault"
