#!/bin/bash
# This script guides users through setting up HashiCorp Cloud Platform (HCP) Vault
# using the HCP portal at https://portal.cloud.hashicorp.com/
# It provides step-by-step instructions and helps capture necessary information

# Set default values
OUTPUT_FILE="hcp-vault-config.env"
OPEN_BROWSER=true
VERBOSE=false

# Print usage
function usage() {
  echo -n "
Usage: $0 [OPTIONS]

This script guides you through setting up HashiCorp Cloud Platform (HCP) Vault
using the HCP portal at https://portal.cloud.hashicorp.com/

Options:
  -o, --output-file      File to save configuration to (default: hcp-vault-config.env)
  -n, --no-browser       Don't open browser automatically
  -v, --verbose          Enable verbose output
  -h, --help             Display this help message

Example:
  $0 --output-file my-hcp-config.env
"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -o|--output-file)
      OUTPUT_FILE="$2"
      shift
      shift
      ;;
    -n|--no-browser)
      OPEN_BROWSER=false
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

# Function to log verbose messages
function log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "$1"
  fi
}

# Function to open URL in browser
function open_url() {
  url="$1"
  if [ "$OPEN_BROWSER" = true ]; then
    echo "Opening $url in your default browser..."
    
    # Detect OS and open browser accordingly
    case "$(uname -s)" in
      Darwin)
        # macOS
        open "$url"
        ;;
      Linux)
        # Linux
        if command -v xdg-open &> /dev/null; then
          xdg-open "$url"
        elif command -v gnome-open &> /dev/null; then
          gnome-open "$url"
        else
          echo "Could not detect a browser opener. Please open the URL manually: $url"
        fi
        ;;
      CYGWIN*|MINGW*|MSYS*)
        # Windows
        start "$url"
        ;;
      *)
        echo "Could not detect your operating system. Please open the URL manually: $url"
        ;;
    esac
  else
    echo "Please open the following URL in your browser: $url"
  fi
}

# Function to prompt for input with validation
function prompt_input() {
  local prompt="$1"
  local var_name="$2"
  local validation_func="$3"
  local default_value="$4"
  
  local input=""
  local valid=false
  
  while [ "$valid" = false ]; do
    if [ -n "$default_value" ]; then
      read -p "$prompt [$default_value]: " input
      if [ -z "$input" ]; then
        input="$default_value"
      fi
    else
      read -p "$prompt: " input
    fi
    
    if [ -n "$validation_func" ]; then
      if $validation_func "$input"; then
        valid=true
      else
        echo "Invalid input. Please try again."
      fi
    else
      valid=true
    fi
  done
  
  eval "$var_name=\"$input\""
}

# Validation functions
function validate_not_empty() {
  [ -n "$1" ]
}

function validate_token() {
  [[ "$1" =~ ^hvs\. ]]
}

# Welcome message
echo "=========================================================="
echo "  HashiCorp Cloud Platform (HCP) Vault Setup Guide"
echo "=========================================================="
echo ""
echo "This script will guide you through setting up HCP Vault"
echo "using the HCP portal at https://portal.cloud.hashicorp.com/"
echo ""
echo "You will need:"
echo "  - An HCP account (free tier available)"
echo "  - A credit card for verification (free tier has no charges)"
echo "  - A few minutes to complete the setup process"
echo ""
echo "The script will help you capture the necessary information"
echo "for use with the OpenShift installation workflows."
echo ""
read -p "Press Enter to continue..."
echo ""

# Step 1: Sign up or sign in to HCP
echo "Step 1: Sign up or sign in to HashiCorp Cloud Platform"
echo "---------------------------------------------------"
echo "You need to sign up for an HCP account if you don't have one already."
echo "If you already have an account, you can sign in."
echo ""
open_url "https://portal.cloud.hashicorp.com/sign-up"
echo ""
read -p "Press Enter once you have signed up or signed in..."
echo ""

# Step 2: Create a new HCP organization if needed
echo "Step 2: Create or select an HCP organization"
echo "-------------------------------------------"
echo "If you're a new user, an organization will be created for you automatically."
echo "If you're part of multiple organizations, select the one you want to use."
echo ""
prompt_input "Enter your HCP organization name" HCP_ORGANIZATION validate_not_empty
echo ""

# Step 3: Create a new HCP project if needed
echo "Step 3: Create or select an HCP project"
echo "--------------------------------------"
echo "You need to create a project or select an existing one."
echo "To create a new project:"
echo "1. Go to the HCP portal: https://portal.cloud.hashicorp.com/"
echo "2. Click on 'Projects' in the left sidebar"
echo "3. Click 'New Project'"
echo "4. Enter a project name and click 'Create Project'"
echo ""
open_url "https://portal.cloud.hashicorp.com/projects"
echo ""
prompt_input "Enter your HCP project name" HCP_PROJECT validate_not_empty
echo ""

# Step 4: Create a new HCP Vault cluster
echo "Step 4: Create an HCP Vault cluster"
echo "---------------------------------"
echo "Now you'll create a new HCP Vault cluster:"
echo "1. Go to the HCP Vault page: https://portal.cloud.hashicorp.com/services/vault"
echo "2. Click 'Create Cluster'"
echo "3. Select your project: $HCP_PROJECT"
echo "4. Choose 'Development (Free)' tier"
echo "5. Enter a cluster name"
echo "6. Select a region (e.g., us-west-2)"
echo "7. Click 'Create Cluster'"
echo ""
open_url "https://portal.cloud.hashicorp.com/services/vault"
echo ""
prompt_input "Enter your HCP Vault cluster name" HCP_VAULT_CLUSTER validate_not_empty
prompt_input "Enter the region you selected" HCP_VAULT_REGION validate_not_empty "us-west-2"
echo ""
echo "Your cluster is now being created. This may take a few minutes."
read -p "Press Enter once your cluster is ready..."
echo ""

# Step 5: Generate an admin token
echo "Step 5: Generate an admin token"
echo "-----------------------------"
echo "Now you'll generate an admin token for your Vault cluster:"
echo "1. Go to your Vault cluster page"
echo "2. Click on 'Access' in the left sidebar"
echo "3. Click 'Generate Token'"
echo "4. Select 'Admin' role"
echo "5. Set an appropriate TTL (e.g., 768h for 32 days)"
echo "6. Click 'Generate Token'"
echo "7. Copy the generated token (it starts with 'hvs.')"
echo ""
open_url "https://portal.cloud.hashicorp.com/services/vault"
echo ""
prompt_input "Enter the generated admin token" HCP_VAULT_TOKEN validate_token
echo ""

# Save configuration to file
echo "Saving configuration to $OUTPUT_FILE..."
cat > "$OUTPUT_FILE" << EOF
# HCP Vault Configuration
# Generated on $(date)
# For use with OpenShift installation workflows

# HCP Organization, Project, and Cluster information
export HCP_ORGANIZATION="$HCP_ORGANIZATION"
export HCP_PROJECT="$HCP_PROJECT"
export HCP_VAULT_CLUSTER="$HCP_VAULT_CLUSTER"
export HCP_VAULT_REGION="$HCP_VAULT_REGION"
export HCP_VAULT_TOKEN="$HCP_VAULT_TOKEN"

# HCP Vault URL
export VAULT_ADDR="https://$HCP_VAULT_CLUSTER.vault.$HCP_VAULT_REGION.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
export VAULT_TOKEN="$HCP_VAULT_TOKEN"

# GitHub Actions secrets
# Add these secrets to your GitHub repository:
# - HCP_ORGANIZATION
# - HCP_PROJECT
# - HCP_VAULT_CLUSTER
# - HCP_VAULT_REGION
# - HCP_VAULT_TOKEN
EOF

chmod 600 "$OUTPUT_FILE"
echo "Configuration saved to $OUTPUT_FILE"
echo ""

# Print next steps
echo "=========================================================="
echo "  HCP Vault Setup Complete!"
echo "=========================================================="
echo ""
echo "Your HCP Vault cluster is now set up and ready to use."
echo ""
echo "Next Steps:"
echo ""
echo "1. Load the configuration into your environment:"
echo "   source $OUTPUT_FILE"
echo ""
echo "2. Set up the required secrets engines and policies:"
echo "   ./scripts/setup-hcp-vault.sh \\"
echo "     --organization \"$HCP_ORGANIZATION\" \\"
echo "     --project \"$HCP_PROJECT\" \\"
echo "     --cluster \"$HCP_VAULT_CLUSTER\" \\"
echo "     --region \"$HCP_VAULT_REGION\" \\"
echo "     --token \"$HCP_VAULT_TOKEN\" \\"
echo "     --example-secrets"
echo ""
echo "3. Add the following secrets to your GitHub repository:"
echo "   - HCP_ORGANIZATION: $HCP_ORGANIZATION"
echo "   - HCP_PROJECT: $HCP_PROJECT"
echo "   - HCP_VAULT_CLUSTER: $HCP_VAULT_CLUSTER"
echo "   - HCP_VAULT_REGION: $HCP_VAULT_REGION"
echo "   - HCP_VAULT_TOKEN: $HCP_VAULT_TOKEN"
echo ""
echo "For more information on HCP Vault, visit:"
echo "https://developer.hashicorp.com/hcp/docs/vault"
echo ""
echo "For more information on using HCP Vault with OpenShift installation workflows,"
echo "see the vault-setup-guide.md file in this repository."
echo ""
