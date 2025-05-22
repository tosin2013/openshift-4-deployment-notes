# HCP Vault Setup with Service Principal Authentication

This guide explains how to use the `setup-hcp-vault-cli.py` script with HCP Service Principal authentication, which is the recommended and more secure method compared to using admin tokens.

## Prerequisites

1. **HCP Account**: You need access to [HashiCorp Cloud Platform](https://portal.cloud.hashicorp.com/)
2. **HCP Vault Cluster**: A Vault cluster must already be created in HCP
3. **HCP CLI**: Install the HCP CLI from [here](https://developer.hashicorp.com/hcp/docs/cli/install)
4. **Vault CLI**: Install the Vault CLI from [here](https://developer.hashicorp.com/vault/downloads)

## Step 1: Create a Service Principal

1. Log into the [HCP Portal](https://portal.cloud.hashicorp.com/)
2. Navigate to your organization
3. Go to **Access control (IAM)** > **Service principals**
4. Click **Create service principal**
5. Give it a name (e.g., "vault-automation")
6. Assign appropriate permissions (at minimum, Vault admin access)
7. Click **Create**

## Step 2: Generate Service Principal Keys

1. Click on your newly created service principal
2. Go to the **Keys** tab
3. Click **Generate key**
4. Copy the **Client ID** and **Client Secret** - save them securely!

## Step 3: Set Up Environment Variables

Create a `.env` file or export environment variables:

```bash
# Copy the example file
cp scripts/hcp-vault-config.example.env scripts/hcp-vault-config.env

# Edit the file with your values
export HCP_CLIENT_ID="your-service-principal-client-id"
export HCP_CLIENT_SECRET="your-service-principal-client-secret"
export HCP_ORGANIZATION="your-organization-name"
export HCP_PROJECT="your-project-name"
export HCP_VAULT_CLUSTER="your-vault-cluster-name"
export HCP_VAULT_REGION="us-west-2"  # or your region
```

## Step 4: Load Environment Variables

```bash
source scripts/hcp-vault-config.env
```

## Step 5: Run the Setup Script

### Option A: Using Environment Variables

```bash
python3 scripts/setup-hcp-vault-cli.py \
  --organization "$HCP_ORGANIZATION" \
  --project "$HCP_PROJECT" \
  --cluster "$HCP_VAULT_CLUSTER"
```

### Option B: Using Command Line Arguments

```bash
python3 scripts/setup-hcp-vault-cli.py \
  --organization "your-org" \
  --project "your-project" \
  --cluster "your-cluster" \
  --client-id "your-client-id" \
  --client-secret "your-client-secret"
```

### Option C: Using Configuration File

```bash
# Copy and edit the JSON config
cp scripts/hcp-vault-config.example.json scripts/hcp-vault-config.json
# Edit the file with your values

# Run with config file
python3 scripts/setup-hcp-vault-cli.py --config scripts/hcp-vault-config.json
```

## Additional Options

### Create Example Secrets for Testing

```bash
python3 scripts/setup-hcp-vault-cli.py \
  --organization "$HCP_ORGANIZATION" \
  --project "$HCP_PROJECT" \
  --cluster "$HCP_VAULT_CLUSTER" \
  --example-secrets
```

### Dry Run Mode (See What Would Be Done)

```bash
python3 scripts/setup-hcp-vault-cli.py \
  --organization "$HCP_ORGANIZATION" \
  --project "$HCP_PROJECT" \
  --cluster "$HCP_VAULT_CLUSTER" \
  --dry-run
```

### Save Configuration File

```bash
python3 scripts/setup-hcp-vault-cli.py \
  --organization "$HCP_ORGANIZATION" \
  --project "$HCP_PROJECT" \
  --cluster "$HCP_VAULT_CLUSTER" \
  --output-config hcp-vault-setup.env
```

## What the Script Does

1. **Authenticates with HCP** using your Service Principal
2. **Obtains a Vault token** from HCP automatically
3. **Sets up KV secrets engines** for all platforms (aws, rosa, gcp, azure, aro, openshift)
4. **Creates a GitHub Actions policy** with appropriate permissions
5. **Optionally creates example secrets** for testing

## Advantages of Service Principal Authentication

- **More Secure**: Service Principals can have limited, specific permissions
- **Automated**: No need to manually generate and manage admin tokens
- **Auditable**: All actions are logged under the Service Principal identity
- **Renewable**: Keys can be rotated without affecting the Vault cluster
- **Scalable**: Can be used in CI/CD pipelines and automation

## Troubleshooting

### HCP CLI Not Found
```bash
# Install HCP CLI
# macOS
brew install hashicorp/tap/hcp

# Linux/Windows - see https://developer.hashicorp.com/hcp/docs/cli/install
```

### Authentication Errors
- Verify your Client ID and Client Secret are correct
- Ensure the Service Principal has appropriate permissions
- Check that your organization, project, and cluster names are correct

### Vault Connection Errors
- Verify the Vault cluster is running and accessible
- Check the region is correct
- Ensure the Service Principal has Vault access permissions

## Security Best Practices

1. **Store credentials securely**: Never commit `.env` files with real credentials
2. **Use least privilege**: Give Service Principals only the permissions they need
3. **Rotate keys regularly**: Generate new Service Principal keys periodically
4. **Monitor access**: Review audit logs for Service Principal usage
5. **Use in CI/CD**: Perfect for automated deployments and testing

## Next Steps

After running the setup script, you can:

1. **Add secrets to GitHub**: Use the displayed GitHub repository secrets
2. **Store real secrets**: Replace example secrets with actual credentials
3. **Test the setup**: Run the OpenShift installation workflows
4. **Monitor usage**: Check HCP audit logs for activity
