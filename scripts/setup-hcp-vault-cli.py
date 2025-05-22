#!/usr/bin/env python3
"""
HCP Vault CLI Setup Script

This script automates the setup of HashiCorp Cloud Platform (HCP) Vault
for use with OpenShift installation workflows. It is idempotent and can be
safely re-run multiple times.

Author: OpenShift 4 Deployment Notes
License: MIT
"""

import argparse
import json
import logging
import os
import ssl
import subprocess
import sys
import tempfile
import urllib.request
import urllib.parse
from dataclasses import dataclass
from typing import Dict, List, Tuple


@dataclass
class HCPVaultConfig:
    """Configuration for HCP Vault setup."""
    organization: str
    project: str
    cluster: str
    region: str = "us-west-2"
    token: str = ""
    client_id: str = ""
    client_secret: str = ""
    secrets_path_prefix: str = ""
    example_secrets: bool = False
    dry_run: bool = False
    verbose: bool = False

    @property
    def vault_url(self) -> str:
        """Generate the HCP Vault URL."""
        return f"https://{self.cluster}.vault.{self.region}.hashicorp.cloud:8200"

    @property
    def uses_service_principal(self) -> bool:
        """Check if using Service Principal authentication."""
        return bool(self.client_id and self.client_secret)

    @property
    def auth_method(self) -> str:
        """Get the authentication method being used."""
        if self.uses_service_principal:
            return "Service Principal"
        elif self.token:
            return "Admin Token"
        else:
            return "None"


class VaultCLI:
    """Wrapper for Vault CLI operations."""

    def __init__(self, config: HCPVaultConfig):
        self.config = config
        self.env = os.environ.copy()
        self.env.update({
            'VAULT_ADDR': config.vault_url,
            'VAULT_NAMESPACE': 'admin'
        })

        # Set authentication environment variables
        if config.uses_service_principal:
            self.env.update({
                'HCP_CLIENT_ID': config.client_id,
                'HCP_CLIENT_SECRET': config.client_secret
            })
        elif config.token:
            self.env.update({
                'VAULT_TOKEN': config.token
            })

    def run_command(self, cmd: List[str]) -> Tuple[bool, str]:
        """Run a vault command and return success status and output."""
        try:
            if self.config.dry_run:
                logging.info(f"[DRY RUN] Would execute: vault {' '.join(cmd)}")
                return True, ""

            result = subprocess.run(
                ['vault'] + cmd,
                env=self.env,
                capture_output=True,
                text=True,
                check=False
            )

            if result.returncode == 0:
                return True, result.stdout.strip()
            else:
                logging.error(f"Vault command failed: {result.stderr.strip()}")
                return False, result.stderr.strip()

        except FileNotFoundError:
            logging.error("Vault CLI not found. Please install Vault CLI first.")
            logging.error("Visit https://developer.hashicorp.com/vault/downloads")
            return False, "Vault CLI not installed"
        except Exception as e:
            logging.error(f"Error running vault command: {e}")
            return False, str(e)

    def authenticate_hcp(self) -> bool:
        """Authenticate with HCP using Service Principal if needed."""
        if not self.config.uses_service_principal:
            return True  # No HCP authentication needed for direct token

        logging.info("Setting up HCP Service Principal authentication...")

        # For Service Principal authentication, we just need to ensure the environment
        # variables are set correctly. The actual authentication happens in vault hcp connect
        if self.config.dry_run:
            logging.info("[DRY RUN] Would set up HCP Service Principal authentication")
            return True

        # Verify that the environment variables are set
        if not self.config.client_id or not self.config.client_secret:
            logging.error("HCP Service Principal credentials not found")
            logging.error("Please set HCP_CLIENT_ID and HCP_CLIENT_SECRET environment variables")
            return False

        logging.info("✓ HCP Service Principal credentials configured")
        return True

    def test_connection(self) -> bool:
        """Test connection to HCP Vault."""
        logging.info(f"Testing connection to HCP Vault at {self.config.vault_url}...")

        # For Service Principal, we need to get a Vault token first
        if self.config.uses_service_principal:
            if not self.get_vault_token_from_hcp():
                return False

        success, _ = self.run_command(['status'])

        if success:
            logging.info("✓ Successfully connected to HCP Vault!")
            return True
        else:
            logging.error("✗ Failed to connect to HCP Vault")
            logging.error("Please check your credentials and try again")
            return False

    def get_vault_token_from_hcp(self) -> bool:
        """Get a Vault token from HCP using the HCP API."""
        if self.config.dry_run:
            logging.info("[DRY RUN] Would get Vault token from HCP API")
            return True

        try:
            # Step 1: Get an HCP access token using Service Principal
            logging.info("Getting HCP access token...")
            hcp_token = self._get_hcp_access_token()
            if not hcp_token:
                return False

            # Step 2: Use HCP access token to get a Vault admin token
            logging.info("Getting Vault admin token from HCP...")
            vault_token = self._get_vault_admin_token(hcp_token)
            if not vault_token:
                return False

            # Step 3: Set the Vault token in environment
            self.env['VAULT_TOKEN'] = vault_token
            logging.info("✓ Successfully obtained Vault token from HCP")
            return True

        except Exception as e:
            logging.error(f"Error getting Vault token from HCP: {e}")
            return False

    def _get_hcp_access_token(self) -> str:
        """Get an HCP access token using Service Principal credentials."""
        try:
            # HCP OAuth2 endpoint
            url = "https://auth.idp.hashicorp.com/oauth2/token"

            # Prepare the request data
            data = {
                'grant_type': 'client_credentials',
                'client_id': self.config.client_id,
                'client_secret': self.config.client_secret,
                'audience': 'https://api.hashicorp.cloud'
            }

            # Encode the data
            encoded_data = urllib.parse.urlencode(data).encode('utf-8')

            # Create the request
            req = urllib.request.Request(
                url,
                data=encoded_data,
                headers={
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'User-Agent': 'hcp-vault-setup-script/1.0'
                }
            )

            # Create SSL context that can handle certificates properly
            ssl_context = ssl.create_default_context()

            # Make the request
            with urllib.request.urlopen(req, context=ssl_context) as response:
                if response.status == 200:
                    result = json.loads(response.read().decode('utf-8'))
                    return result.get('access_token', '')
                else:
                    logging.error(f"Failed to get HCP access token: HTTP {response.status}")
                    return ""

        except Exception as e:
            logging.error(f"Error getting HCP access token: {e}")
            return ""

    def _get_vault_admin_token(self, hcp_token: str) -> str:
        """Get a Vault admin token using HCP access token."""
        try:
            # HCP Vault admin token endpoint
            url = f"https://api.cloud.hashicorp.com/vault/2020-11-25/organizations/{self.config.organization}/projects/{self.config.project}/clusters/{self.config.cluster}:generateAdminToken"

            # Create the request
            req = urllib.request.Request(
                url,
                method='POST',
                headers={
                    'Authorization': f'Bearer {hcp_token}',
                    'Content-Type': 'application/json',
                    'User-Agent': 'hcp-vault-setup-script/1.0'
                }
            )

            # Create SSL context that can handle certificates properly
            ssl_context = ssl.create_default_context()

            # Make the request
            with urllib.request.urlopen(req, context=ssl_context) as response:
                if response.status == 200:
                    result = json.loads(response.read().decode('utf-8'))
                    return result.get('token', '')
                else:
                    logging.error(f"Failed to get Vault admin token: HTTP {response.status}")
                    return ""

        except Exception as e:
            logging.error(f"Error getting Vault admin token: {e}")
            return ""

    def list_secrets_engines(self) -> Dict[str, dict]:
        """List all enabled secrets engines."""
        success, output = self.run_command(['secrets', 'list', '-format=json'])
        if success and output:
            try:
                return json.loads(output)
            except json.JSONDecodeError:
                logging.error("Failed to parse secrets engines list")
        return {}

    def enable_kv_engine(self, path: str) -> bool:
        """Enable KV secrets engine at the specified path (idempotent)."""
        full_path = f"{self.config.secrets_path_prefix}{path}"

        # Check if already enabled
        engines = self.list_secrets_engines()
        engine_path = f"{full_path}/"

        if engine_path in engines:
            logging.info(f"✓ KV secrets engine already enabled at {full_path}")
            return True

        logging.info(f"Enabling KV secrets engine at {full_path}...")
        success, _ = self.run_command([
            'secrets', 'enable',
            '-version=2',
            f'-path={full_path}',
            'kv'
        ])

        if success:
            logging.info(f"✓ KV secrets engine enabled at {full_path}")
            return True
        else:
            logging.error(f"✗ Failed to enable KV secrets engine at {full_path}")
            return False

    def list_policies(self) -> List[str]:
        """List all policies."""
        success, output = self.run_command(['policy', 'list', '-format=json'])
        if success and output:
            try:
                return json.loads(output)
            except json.JSONDecodeError:
                logging.error("Failed to parse policies list")
        return []

    def create_policy(self, name: str, policy_content: str) -> bool:
        """Create or update a policy (idempotent)."""
        policies = self.list_policies()

        if name in policies:
            logging.info(f"✓ Policy '{name}' already exists, updating...")
        else:
            logging.info(f"Creating policy '{name}'...")

        # Write policy to temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.hcl', delete=False) as f:
            f.write(policy_content)
            policy_file = f.name

        try:
            success, _ = self.run_command(['policy', 'write', name, policy_file])

            if success:
                action = "updated" if name in policies else "created"
                logging.info(f"✓ Policy '{name}' {action} successfully")
                return True
            else:
                logging.error(f"✗ Failed to create/update policy '{name}'")
                return False
        finally:
            # Clean up temporary file
            if not self.config.dry_run:
                os.unlink(policy_file)

    def secret_exists(self, path: str) -> bool:
        """Check if a secret exists at the given path."""
        success, _ = self.run_command(['kv', 'get', '-format=json', path])
        return success

    def create_secret(self, path: str, data: Dict[str, str]) -> bool:
        """Create a secret (idempotent - skip if exists)."""
        if self.secret_exists(path):
            logging.info(f"✓ Secret already exists at {path}, skipping")
            return True

        logging.info(f"Creating secret at {path}...")

        # Build command with key-value pairs
        cmd = ['kv', 'put', path]
        for key, value in data.items():
            cmd.append(f"{key}={value}")

        success, _ = self.run_command(cmd)

        if success:
            logging.info(f"✓ Secret created at {path}")
            return True
        else:
            logging.error(f"✗ Failed to create secret at {path}")
            return False


class HCPVaultSetup:
    """Main class for HCP Vault setup operations."""

    PLATFORMS = ["aws", "rosa", "gcp", "azure", "aro", "openshift"]

    def __init__(self, config: HCPVaultConfig):
        self.config = config
        self.vault = VaultCLI(config)

        # Setup logging
        log_level = logging.DEBUG if config.verbose else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

    def validate_config(self) -> bool:
        """Validate the configuration."""
        # Check required basic parameters
        if not all([
            self.config.organization,
            self.config.project,
            self.config.cluster
        ]):
            logging.error("Missing required parameters: organization, project, and cluster are required")
            return False

        # Check authentication method
        has_token = bool(self.config.token)
        has_service_principal = bool(self.config.client_id and self.config.client_secret)

        if not has_token and not has_service_principal:
            logging.error("Authentication required: provide either --token or both --client-id and --client-secret")
            logging.error("You can also set HCP_CLIENT_ID and HCP_CLIENT_SECRET environment variables")
            return False

        if has_token and has_service_principal:
            logging.warning("Both token and service principal provided. Service principal will be used.")

        # Validate token format if provided
        if has_token and not self.config.token.startswith('hvs.'):
            logging.warning("Token does not start with 'hvs.' - this may not be a valid HCP Vault token")

        return True

    def setup_secrets_engines(self) -> bool:
        """Set up KV secrets engines for all platforms."""
        logging.info("Setting up KV secrets engines...")

        success = True
        for platform in self.PLATFORMS:
            if not self.vault.enable_kv_engine(platform):
                success = False

        if success:
            logging.info("✓ All KV secrets engines set up successfully!")
        else:
            logging.error("✗ Some KV secrets engines failed to set up")

        return success

    def create_github_actions_policy(self) -> bool:
        """Create GitHub Actions policy for accessing secrets."""
        logging.info("Creating GitHub Actions policy...")

        policy_content = f"""# Allow reading platform secrets
path "{self.config.secrets_path_prefix}aws/*" {{
  capabilities = ["read"]
}}

path "{self.config.secrets_path_prefix}rosa/*" {{
  capabilities = ["read"]
}}

path "{self.config.secrets_path_prefix}gcp/*" {{
  capabilities = ["read"]
}}

path "{self.config.secrets_path_prefix}azure/*" {{
  capabilities = ["read"]
}}

path "{self.config.secrets_path_prefix}aro/*" {{
  capabilities = ["read"]
}}

# Allow reading and writing kubeconfig
path "{self.config.secrets_path_prefix}openshift/*" {{
  capabilities = ["read", "create", "update"]
}}"""

        success = self.vault.create_policy("github-actions", policy_content)

        if success:
            logging.info("✓ GitHub Actions policy created successfully!")
        else:
            logging.error("✗ Failed to create GitHub Actions policy")

        return success

    def create_example_secrets(self) -> bool:
        """Create example secrets for testing (idempotent)."""
        if not self.config.example_secrets:
            return True

        logging.info("Creating example secrets...")
        logging.warning("IMPORTANT: These are example secrets with dummy values.")
        logging.warning("Replace them with real values before using in production.")

        success = True

        # Define example secrets for each platform
        example_secrets = {
            "aws": {
                "pullsecret": {"pull_secret": "example-pull-secret"},
                "sshkey": {"private_key": "example-private-key", "public_key": "example-public-key"},
                "credentials": {"aws_access_key_id": "example-access-key", "aws_secret_access_key": "example-secret-key"}
            },
            "rosa": {
                "pullsecret": {"pull_secret": "example-pull-secret"},
                "sshkey": {"private_key": "example-private-key", "public_key": "example-public-key"},
                "credentials": {"aws_access_key_id": "example-access-key", "aws_secret_access_key": "example-secret-key"}
            },
            "gcp": {
                "pullsecret": {"pull_secret": "example-pull-secret"},
                "sshkey": {"private_key": "example-private-key", "public_key": "example-public-key"},
                "credentials": {"service_account_key": '{"type":"service_account","project_id":"example"}'}
            },
            "azure": {
                "pullsecret": {"pull_secret": "example-pull-secret"},
                "sshkey": {"private_key": "example-private-key", "public_key": "example-public-key"},
                "credentials": {
                    "client_id": "example-client-id",
                    "client_secret": "example-client-secret",
                    "tenant_id": "example-tenant-id",
                    "subscription_id": "example-subscription-id"
                }
            },
            "aro": {
                "pullsecret": {"pull_secret": "example-pull-secret"},
                "sshkey": {"private_key": "example-private-key", "public_key": "example-public-key"},
                "credentials": {
                    "client_id": "example-client-id",
                    "client_secret": "example-client-secret",
                    "tenant_id": "example-tenant-id",
                    "subscription_id": "example-subscription-id"
                }
            }
        }

        # Create secrets for each platform
        for platform, secrets in example_secrets.items():
            logging.info(f"Creating example secrets for {platform}...")
            for secret_name, secret_data in secrets.items():
                path = f"{self.config.secrets_path_prefix}{platform}/{secret_name}"
                if not self.vault.create_secret(path, secret_data):
                    success = False

        if success:
            logging.info("✓ Example secrets created successfully!")
        else:
            logging.error("✗ Some example secrets failed to create")

        return success

    def print_summary(self) -> None:
        """Print setup summary and next steps."""
        logging.info("=" * 60)
        logging.info("  HCP Vault Setup Complete!")
        logging.info("=" * 60)
        logging.info("")
        logging.info("Use the following GitHub repository secrets for your workflows:")
        logging.info(f"  HCP_ORGANIZATION: {self.config.organization}")
        logging.info(f"  HCP_PROJECT: {self.config.project}")
        logging.info(f"  HCP_VAULT_CLUSTER: {self.config.cluster}")
        logging.info(f"  HCP_VAULT_REGION: {self.config.region}")
        logging.info(f"  HCP_VAULT_TOKEN: {self.config.token}")
        logging.info("")
        logging.info("To use the Vault CLI with this HCP Vault instance:")
        logging.info(f"  export VAULT_ADDR='{self.config.vault_url}'")
        logging.info(f"  export VAULT_TOKEN='{self.config.token}'")
        logging.info("  export VAULT_NAMESPACE='admin'")
        logging.info("")
        logging.info("For more information:")
        logging.info("  https://developer.hashicorp.com/hcp/docs/vault")

    def save_config_file(self, output_file: str) -> bool:
        """Save configuration to a shell script file."""
        try:
            config_content = f"""# HCP Vault Configuration
# Generated on {os.popen('date').read().strip()}
# For use with OpenShift installation workflows

# HCP Organization, Project, and Cluster information
export HCP_ORGANIZATION="{self.config.organization}"
export HCP_PROJECT="{self.config.project}"
export HCP_VAULT_CLUSTER="{self.config.cluster}"
export HCP_VAULT_REGION="{self.config.region}"
export HCP_VAULT_TOKEN="{self.config.token}"

# HCP Vault URL
export VAULT_ADDR="{self.config.vault_url}"
export VAULT_NAMESPACE="admin"
export VAULT_TOKEN="{self.config.token}"

# GitHub Actions secrets
# Add these secrets to your GitHub repository:
# - HCP_ORGANIZATION
# - HCP_PROJECT
# - HCP_VAULT_CLUSTER
# - HCP_VAULT_REGION
# - HCP_VAULT_TOKEN
"""

            if self.config.dry_run:
                logging.info(f"[DRY RUN] Would save configuration to {output_file}")
                return True

            with open(output_file, 'w') as f:
                f.write(config_content)

            # Set restrictive permissions
            os.chmod(output_file, 0o600)

            logging.info(f"✓ Configuration saved to {output_file}")
            return True

        except Exception as e:
            logging.error(f"✗ Failed to save configuration file: {e}")
            return False

    def run_setup(self) -> bool:
        """Run the complete setup process."""
        steps = [
            ("Authenticating with HCP", self.vault.authenticate_hcp),
            ("Testing connection", self.vault.test_connection),
            ("Setting up secrets engines", self.setup_secrets_engines),
            ("Creating GitHub Actions policy", self.create_github_actions_policy),
            ("Creating example secrets", self.create_example_secrets),
        ]

        for step_name, step_func in steps:
            logging.info(f"Step: {step_name}")
            if not step_func():
                logging.error(f"Setup failed at step: {step_name}")
                return False
            logging.info("")

        self.print_summary()
        return True


def setup_logging(verbose: bool = False):
    """Setup logging configuration."""
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )


def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Set up HCP Vault for OpenShift installation workflows",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using admin token
  %(prog)s --organization myorg --project myproject --cluster myvault --token hvs.example123

  # Using Service Principal
  %(prog)s --organization myorg --project myproject --cluster myvault --client-id abc123 --client-secret xyz789

  # Using configuration file
  %(prog)s --config config.json --example-secrets

  # Dry run mode
  %(prog)s --organization myorg --project myproject --cluster myvault --token hvs.example123 --dry-run
        """
    )

    parser.add_argument(
        '-o', '--organization',
        help='HCP organization name (required)'
    )
    parser.add_argument(
        '-p', '--project',
        help='HCP project name (required)'
    )
    parser.add_argument(
        '-c', '--cluster',
        help='HCP Vault cluster name (required)'
    )
    parser.add_argument(
        '-r', '--region',
        default='us-west-2',
        help='HCP region (default: us-west-2)'
    )
    parser.add_argument(
        '-t', '--token',
        help='HCP Vault token (required if not using service principal)'
    )
    parser.add_argument(
        '--client-id',
        help='HCP Service Principal Client ID (alternative to token)'
    )
    parser.add_argument(
        '--client-secret',
        help='HCP Service Principal Client Secret (alternative to token)'
    )
    parser.add_argument(
        '-s', '--secrets-path',
        default='',
        help='Path prefix for secrets (default: none)'
    )
    parser.add_argument(
        '-e', '--example-secrets',
        action='store_true',
        help='Create example secrets (default: false)'
    )
    parser.add_argument(
        '--config',
        help='Configuration file (JSON format)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be done without making changes'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    parser.add_argument(
        '--output-config',
        help='Save configuration to file (shell format)'
    )

    return parser.parse_args()


def load_config_from_file(config_file: str) -> dict:
    """Load configuration from JSON file."""
    try:
        with open(config_file, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logging.error(f"Configuration file not found: {config_file}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON in configuration file: {e}")
        sys.exit(1)


def main():
    """Main function."""
    args = parse_arguments()

    # Setup logging early
    setup_logging(args.verbose)

    # Load configuration
    config_data = {}
    if args.config:
        config_data = load_config_from_file(args.config)

    # Command line arguments override config file and environment variables
    config = HCPVaultConfig(
        organization=args.organization or config_data.get('organization', ''),
        project=args.project or config_data.get('project', ''),
        cluster=args.cluster or config_data.get('cluster', ''),
        region=args.region or config_data.get('region', 'us-west-2'),
        token=args.token or config_data.get('token', ''),
        client_id=args.client_id or config_data.get('client_id', '') or os.getenv('HCP_CLIENT_ID', ''),
        client_secret=args.client_secret or config_data.get('client_secret', '') or os.getenv('HCP_CLIENT_SECRET', ''),
        secrets_path_prefix=args.secrets_path or config_data.get('secrets_path_prefix', ''),
        example_secrets=args.example_secrets or config_data.get('example_secrets', False),
        dry_run=args.dry_run,
        verbose=args.verbose
    )

    # Initialize setup
    setup = HCPVaultSetup(config)

    # Validate configuration
    if not setup.validate_config():
        sys.exit(1)

    # Display configuration
    logging.info("HCP Vault Setup Configuration:")
    logging.info(f"  Organization: {config.organization}")
    logging.info(f"  Project: {config.project}")
    logging.info(f"  Cluster: {config.cluster}")
    logging.info(f"  Region: {config.region}")
    logging.info(f"  URL: {config.vault_url}")
    logging.info(f"  Authentication: {config.auth_method}")
    logging.info(f"  Dry Run: {config.dry_run}")
    logging.info("")

    if config.dry_run:
        logging.info("DRY RUN MODE - No changes will be made")
        logging.info("")

    # Run the complete setup
    if not setup.run_setup():
        sys.exit(1)

    # Save configuration file if requested
    if args.output_config:
        if not setup.save_config_file(args.output_config):
            sys.exit(1)


if __name__ == '__main__':
    main()
