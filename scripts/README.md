# HashiCorp Vault Setup Scripts

This directory contains scripts for setting up HashiCorp Vault for use with OpenShift 4.18 installation workflows. We support both **cloud-hosted** and **self-hosted** Vault options to accommodate different user preferences and deployment scenarios.

## 🏗️ Architecture Overview

### Cloud-Hosted: HCP Vault Secrets (Recommended for Most Users)
- **Service**: HashiCorp Cloud Platform (HCP) Vault Secrets
- **Hosting**: Fully managed by HashiCorp
- **Complexity**: Simple setup, minimal maintenance
- **Cost**: Free tier available, pay-as-you-go
- **Best for**: Individual developers, small teams, getting started quickly

### Self-Hosted: HCP Vault Dedicated
- **Service**: Full HashiCorp Vault cluster
- **Hosting**: You manage the infrastructure
- **Complexity**: More setup and maintenance required
- **Cost**: Infrastructure costs + Vault license (if applicable)
- **Best for**: Enterprise environments, air-gapped networks, specific compliance requirements

## 🚀 Quick Start

### For Cloud-Hosted (HCP Vault Secrets) - Recommended

1. **Copy the example configuration:**
   ```bash
   cp scripts/hcp-vault-secrets-config.example.env scripts/hcp-vault-secrets-config.env
   ```

2. **Edit the configuration with your HCP details:**
   ```bash
   # Get these from https://portal.cloud.hashicorp.com/
   export HCP_CLIENT_ID="your-service-principal-client-id"
   export HCP_CLIENT_SECRET="your-service-principal-client-secret"
   export HCP_ORGANIZATION="your-organization-name"
   export HCP_PROJECT="your-project-name"
   ```

3. **Load the configuration and set up ALL OpenShift secrets:**
   ```bash
   source scripts/hcp-vault-secrets-config.env
   # You can optionally provide the pull secret directly from a file:
   # python3 scripts/setup-openshift-secrets.py --service vault-secrets --pull-secret-file /path/to/your/pull-secret.json
   python3 scripts/setup-openshift-secrets.py --service vault-secrets
   ```

   This will interactively collect and store:
   - AWS credentials
   - OpenShift pull secret
   - SSH keys for cluster access

### For Self-Hosted (HCP Vault Dedicated)

1. **Copy the example configuration:**
   ```bash
   cp scripts/hcp-vault-config.example.env scripts/hcp-vault-config.env
   ```

2. **Edit the configuration with your HCP Vault cluster details:**
   ```bash
   export HCP_CLIENT_ID="your-service-principal-client-id"
   export HCP_CLIENT_SECRET="your-service-principal-client-secret"
   export HCP_ORGANIZATION="your-organization-name"
   export HCP_PROJECT="your-project-name"
   export HCP_VAULT_CLUSTER="your-vault-cluster-name"
   export HCP_VAULT_REGION="us-west-2"
   ```

3. **Load the configuration and set up ALL OpenShift secrets:**
   ```bash
   source scripts/hcp-vault-config.env
   # You can optionally provide the pull secret directly from a file:
   # python3 scripts/setup-openshift-secrets.py --service vault-dedicated --pull-secret-file /path/to/your/pull-secret.json
   python3 scripts/setup-openshift-secrets.py --service vault-dedicated
   ```

   This will interactively collect and store:
   - AWS credentials
   - OpenShift pull secret
   - SSH keys for cluster access

## 📁 Script Reference

### Universal Scripts (Both Services)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup-openshift-secrets.py` | **🌟 MAIN SCRIPT** - Sets up ALL OpenShift secrets. Supports interactive input and a `--pull-secret-file` argument for the OpenShift pull secret. | **Use this for complete OpenShift deployment setup** |

### Cloud-Hosted Scripts (HCP Vault Secrets)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup-hcp-vault-secrets.py` | Infrastructure setup for HCP Vault Secrets | Only if you need to create the Vault Secrets app |
| `hcp-vault-secrets-config.example.env` | Configuration template | Copy and customize for your environment |

### Self-Hosted Scripts (HCP Vault Dedicated)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup-hcp-vault-cli.py` | Infrastructure setup for HCP Vault Dedicated | Only if you need to create the Vault cluster |
| `setup-hcp-vault.sh` | Bash alternative setup script | If you prefer bash over Python |
| `setup-hcp-vault-portal.sh` | Interactive GUI-based setup guide | For beginners or manual setup preference |
| `hcp-vault-config.example.env` | Environment configuration template | Copy and customize for your environment |
| `hcp-vault-config.example.json` | JSON configuration template | Alternative to .env file format |

### Development & Testing

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup-vault-test-token.sh` | Local Vault dev server | Local development and testing |

### Documentation

| File | Purpose |
|------|---------|
| `README-service-principal.md` | Detailed Service Principal setup guide |

## 🔧 Prerequisites

### For Cloud-Hosted (HCP Vault Secrets)
- HCP account at [portal.cloud.hashicorp.com](https://portal.cloud.hashicorp.com/)
- HCP CLI installed ([installation guide](https://developer.hashicorp.com/hcp/docs/cli/install))
- Service Principal with appropriate permissions

### For Self-Hosted (HCP Vault Dedicated)
- HCP account at [portal.cloud.hashicorp.com](https://portal.cloud.hashicorp.com/)
- HCP CLI installed ([installation guide](https://developer.hashicorp.com/hcp/docs/cli/install))
- Vault CLI installed ([installation guide](https://developer.hashicorp.com/vault/downloads))
- Service Principal with Vault admin permissions

### For Local Development
- Vault CLI installed ([installation guide](https://developer.hashicorp.com/vault/downloads))

## � GitHub Actions Workflow Setup

After setting up your secrets with the scripts above, configure GitHub Actions:

### For HCP Vault Secrets (Cloud-Hosted)

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

```
HCP_CLIENT_ID: your-service-principal-client-id
HCP_CLIENT_SECRET: your-service-principal-client-secret
HCP_ORGANIZATION: your-organization-name
HCP_PROJECT: your-project-name
HCP_VAULT_SECRETS_APP: openshift-secrets
```

### For HCP Vault Dedicated (Self-Hosted)

Add these secrets to your GitHub repository:

```
HCP_ORGANIZATION: your-organization-name
HCP_PROJECT: your-project-name
HCP_VAULT_CLUSTER: your-vault-cluster-name
HCP_VAULT_REGION: us-west-2
HCP_VAULT_TOKEN: your-vault-token
```

### Run the Workflow

1. Go to **Actions** tab in your GitHub repository
2. Select **"AWS OpenShift 4.18 Installation"** workflow
3. Click **"Run workflow"** and provide cluster details
4. The workflow will automatically detect and use your vault service

## �🔐 Security Best Practices

1. **Never commit real credentials** to git repositories
2. **Use Service Principal authentication** instead of admin tokens when possible
3. **Rotate credentials regularly**
4. **Use least-privilege access** for Service Principals
5. **Store sensitive config files** in `.gitignore`

## 🆘 Troubleshooting

### Common Issues

**Authentication Errors:**
- Verify Service Principal credentials are correct
- Check that Service Principal has appropriate permissions
- Ensure organization, project, and cluster names are correct

**Connection Errors:**
- Verify HCP CLI is installed and authenticated
- Check network connectivity to HCP services
- Ensure Vault cluster is running (for self-hosted)

**Script Errors:**
- Check Python version (3.6+ required)
- Verify all required dependencies are installed
- Run with `--verbose` flag for detailed logging

### Getting Help

1. Check the [HCP Vault documentation](https://developer.hashicorp.com/hcp/docs/vault)
2. Review the [OpenShift installation workflows](../.github/workflows/)
3. See the [main vault setup guide](../vault-setup-guide.md)

## 🔄 Migration Between Services

### From Self-Hosted to Cloud-Hosted
If you want to migrate from HCP Vault Dedicated to HCP Vault Secrets:

1. Export your secrets from the self-hosted Vault
2. Set up HCP Vault Secrets using the cloud-hosted scripts
3. Import your secrets to the new service
4. Update your GitHub Actions workflows to use the new service

### From Cloud-Hosted to Self-Hosted
If you want to migrate from HCP Vault Secrets to HCP Vault Dedicated:

1. Export your secrets from HCP Vault Secrets
2. Set up HCP Vault Dedicated using the self-hosted scripts
3. Import your secrets to the new Vault cluster
4. Update your GitHub Actions workflows to use the new cluster

## 📚 Additional Resources

- [HCP Vault Secrets Documentation](https://developer.hashicorp.com/hcp/docs/vault-secrets)
- [HCP Vault Documentation](https://developer.hashicorp.com/hcp/docs/vault)
- [Vault CLI Documentation](https://developer.hashicorp.com/vault/docs/commands)
- [Service Principal Setup Guide](README-service-principal.md)
- [Main Repository Vault Setup Guide](../vault-setup-guide.md)
