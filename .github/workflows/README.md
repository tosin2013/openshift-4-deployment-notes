# OpenShift 4.18 Installation GitHub Actions

This directory contains GitHub Actions workflows for automating OpenShift 4.18 installations across multiple cloud platforms. These workflows leverage existing scripts in the repository and use HashiCorp Vault for secure storage of sensitive information.

## Available Workflows

- **AWS OpenShift Installation** (`aws-openshift-install.yml`): Installs OpenShift 4.18 on AWS using the IPI method
- **ROSA OpenShift Installation** (`rosa-openshift-install.yml`): Installs OpenShift 4.18 on Red Hat OpenShift Service on AWS (ROSA)
- **GCP OpenShift Installation** (`gcp-openshift-install.yml`): Installs OpenShift 4.18 on Google Cloud Platform
- **Azure OpenShift Installation** (`azure-openshift-install.yml`): Installs OpenShift 4.18 on Microsoft Azure using the IPI method
- **ARO OpenShift Installation** (`aro-openshift-install.yml`): Installs OpenShift 4.18 on Azure Red Hat OpenShift (ARO)

## Required GitHub Secrets

To use these workflows, you need to set up GitHub repository secrets based on your HashiCorp Vault configuration. The workflows will attempt to auto-detect the Vault type based on the secrets provided. Choose one of the following options:

### Option 1: For HCP Vault Secrets (Cloud-hosted)
If you are using HashiCorp Cloud Platform (HCP) Vault Secrets (the fully managed secrets-as-a-service offering):
- `HCP_CLIENT_ID`: Your HCP Client ID for authentication.
- `HCP_CLIENT_SECRET`: Your HCP Client Secret for authentication.
- `HCP_ORGANIZATION`: Your HCP organization ID.
- `HCP_PROJECT`: Your HCP project ID.
- `HCP_VAULT_SECRETS_APP`: The name of your application in HCP Vault Secrets.

### Option 2: For HCP Vault Dedicated (Self-managed on HCP)
If you are using HCP Vault Dedicated (a self-managed Vault cluster deployed on HCP infrastructure):
- `HCP_ORGANIZATION`: Your HCP organization ID.
- `HCP_PROJECT`: Your HCP project ID.
- `HCP_VAULT_CLUSTER`: The ID of your Vault cluster on HCP.
- `HCP_VAULT_TOKEN`: A Vault token with permissions to read the required secrets from the `admin` namespace (or adjust workflow if using a different namespace).
- `HCP_VAULT_REGION`: (Optional) The AWS region where your HCP Vault Dedicated cluster is deployed (e.g., `us-west-2`). If not provided, the workflow defaults to `us-west-2`.

### Option 3: For Self-Hosted Vault (Traditional)
If you are using a self-hosted instance of HashiCorp Vault (not on HCP):
- `VAULT_TOKEN`: A Vault token with permissions to read the required secrets.
- `VAULT_ADDR`: (Optional) The URL of your HashiCorp Vault server. If not provided, the workflow defaults to `http://127.0.0.1:8200`.

**Note:** The workflow will use the first complete set of secrets it finds that matches one of these configurations. Ensure you only set the secrets relevant to your specific Vault setup to avoid ambiguity.

## HashiCorp Vault Integration

These workflows use HashiCorp Vault for secure storage of sensitive information. The following secrets are retrieved from Vault:

### AWS and ROSA
- Pull secret at `aws/pullsecret` or `rosa/pullsecret`
- SSH key at `aws/sshkey` or `rosa/sshkey`
- AWS credentials at `aws/credentials` or `rosa/credentials` (if needed)

### GCP
- Pull secret at `gcp/pullsecret`
- SSH key at `gcp/sshkey`
- GCP credentials at `gcp/credentials` (if needed)

### Azure and ARO
- Pull secret at `azure/pullsecret` or `aro/pullsecret`
- SSH key at `azure/sshkey` or `aro/sshkey`
- Azure credentials at `azure/credentials` or `aro/credentials` (if needed)

After successful installation, the kubeconfig is stored in Vault at:
`openshift/<platform>/<cluster-name>/kubeconfig`

## How to Use

1. Set up the required GitHub secret (VAULT_TOKEN)
2. Configure HashiCorp Vault with the necessary secrets
3. Navigate to the Actions tab in your GitHub repository
4. Select the appropriate workflow for your target platform
5. Click "Run workflow"
6. Fill in the required parameters
7. Click "Run workflow" to start the installation

## Relationship to Existing Repository Scripts

These workflows leverage existing scripts in the repository:

- `aws/configure-aws-cli.sh` for AWS CLI setup
- `pre-steps/configure-openshift-packages.sh` for OpenShift packages
- `aws/configure-openshift-installer.sh` for AWS installation
- `rosa/rosa-vpc-for-sts.sh` for ROSA VPC setup
- Similar scripts for other platforms

## Error Handling

In case of installation failure, the workflows will:
1. Report the failure with detailed error messages
2. Provide installation logs (with sensitive information redacted)
3. Suggest manual cleanup steps specific to the platform

## Documentation

For more detailed information about each platform's installation process, refer to the README.md files in the respective platform directories:
- AWS: [aws/README.md](../../aws/README.md)
- ROSA: [rosa/README.md](../../rosa/README.md)
- GCP: [gcp/README.md](../../gcp/README.md)
- Azure: Coming soon
- ARO: [aro/README.md](../../aro/README.md)
