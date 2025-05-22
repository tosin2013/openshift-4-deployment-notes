#!/usr/bin/env python3
"""
HCP Vault Secrets Setup Script

This script automates the setup of HashiCorp Cloud Platform (HCP) Vault Secrets
for use with OpenShift installation workflows. It creates applications and secrets
using the HCP CLI and API. It is idempotent and can be safely re-run multiple times.

Author: OpenShift 4 Deployment Notes
License: MIT
"""

import argparse
import json
import logging
import os
import subprocess
import sys
from dataclasses import dataclass
from typing import List


@dataclass
class HCPVaultSecretsConfig:
    """Configuration for HCP Vault Secrets setup."""
    organization: str
    project: str
    client_id: str = ""
    client_secret: str = ""
    app_name: str = "openshift-secrets"
    example_secrets: bool = False
    dry_run: bool = False
    verbose: bool = False

    @property
    def uses_service_principal(self) -> bool:
        """Check if using Service Principal authentication."""
        return bool(self.client_id and self.client_secret)


class HCPVaultSecretsCLI:
    """Wrapper for HCP Vault Secrets CLI operations."""

    def __init__(self, config: HCPVaultSecretsConfig):
        self.config = config
        self.env = os.environ.copy()
        self.env.update({
            'HCP_CLIENT_ID': config.client_id,
            'HCP_CLIENT_SECRET': config.client_secret
        })

    def authenticate(self) -> bool:
        """Authenticate with HCP using the CLI."""
        if self.config.dry_run:
            logging.info("[DRY RUN] Would authenticate with HCP CLI")
            return True

        try:
            # Check if HCP CLI is available
            result = subprocess.run(['hcp', 'version'], capture_output=True, text=True, check=False)
            if result.returncode != 0:
                logging.error("HCP CLI not found. Please install HCP CLI first.")
                logging.error("Visit https://developer.hashicorp.com/hcp/docs/cli/install")
                return False

            # Authenticate with HCP
            logging.info("Authenticating with HCP...")
            result = subprocess.run([
                'hcp', 'auth', 'login',
                '--client-id', self.config.client_id,
                '--client-secret', self.config.client_secret
            ], env=self.env, capture_output=True, text=True, check=False)

            if result.returncode == 0:
                logging.info("✓ Successfully authenticated with HCP!")
                return True
            else:
                logging.error("✗ Failed to authenticate with HCP")
                logging.error(f"Error: {result.stderr.strip()}")
                return False

        except Exception as e:
            logging.error(f"Error authenticating with HCP: {e}")
            return False

    def list_apps(self) -> List[str]:
        """List all HCP Vault Secrets applications."""
        if self.config.dry_run:
            logging.info("[DRY RUN] Would list HCP Vault Secrets applications")
            return []

        try:
            result = subprocess.run([
                'hcp', 'vault-secrets', 'apps', 'list', '--format=json'
            ], env=self.env, capture_output=True, text=True, check=False)

            if result.returncode == 0:
                apps_data = json.loads(result.stdout)
                # Extract app names from the response
                app_names = []
                if isinstance(apps_data, list):
                    for app in apps_data:
                        if isinstance(app, dict) and 'name' in app:
                            app_names.append(app['name'])
                return app_names
            else:
                logging.error(f"Failed to list apps: {result.stderr}")
                return []

        except Exception as e:
            logging.error(f"Error listing apps: {e}")
            return []

    def create_app(self, app_name: str, description: str = "") -> bool:
        """Create an HCP Vault Secrets application (idempotent)."""
        # Check if app already exists
        apps = self.list_apps()
        if app_name in apps:
            logging.info(f"✓ Application '{app_name}' already exists")
            return True

        if self.config.dry_run:
            logging.info(f"[DRY RUN] Would create application '{app_name}'")
            return True

        try:
            logging.info(f"Creating application '{app_name}'...")

            cmd = ['hcp', 'vault-secrets', 'apps', 'create', app_name]
            if description:
                cmd.extend(['--description', description])

            result = subprocess.run(cmd, env=self.env, capture_output=True, text=True, check=False)

            if result.returncode == 0:
                logging.info(f"✓ Application '{app_name}' created successfully")
                return True
            else:
                logging.error(f"Failed to create app: {result.stderr}")
                return False

        except Exception as e:
            logging.error(f"Error creating app: {e}")
            return False




class HCPVaultSecretsSetup:
    """Main class for HCP Vault Secrets setup operations."""

    PLATFORMS = ["aws", "rosa", "gcp", "azure", "aro", "openshift"]

    def __init__(self, config: HCPVaultSecretsConfig):
        self.config = config
        self.cli = HCPVaultSecretsCLI(config)

        # Setup logging
        log_level = logging.DEBUG if config.verbose else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

    def validate_config(self) -> bool:
        """Validate the configuration."""
        if not all([
            self.config.organization,
            self.config.project,
            self.config.client_id,
            self.config.client_secret
        ]):
            logging.error("Missing required parameters: organization, project, client_id, and client_secret are required")
            logging.error("You can also set HCP_CLIENT_ID and HCP_CLIENT_SECRET environment variables")
            return False

        return True

    def setup_application(self) -> bool:
        """Set up the HCP Vault Secrets application."""
        logging.info(f"Setting up HCP Vault Secrets application '{self.config.app_name}'...")

        description = "OpenShift installation secrets managed by automated setup script"
        success = self.cli.create_app(self.config.app_name, description)

        if success:
            logging.info("✓ HCP Vault Secrets application setup completed!")
        else:
            logging.error("✗ Failed to set up HCP Vault Secrets application")

        return success

    def print_summary(self) -> None:
        """Print setup summary and next steps."""
        logging.info("=" * 60)
        logging.info("  HCP Vault Secrets Setup Complete!")
        logging.info("=" * 60)
        logging.info("")
        logging.info("Use the following GitHub repository secrets for your workflows:")
        logging.info(f"  HCP_CLIENT_ID: {self.config.client_id}")
        logging.info(f"  HCP_CLIENT_SECRET: {self.config.client_secret}")
        logging.info(f"  HCP_ORGANIZATION: {self.config.organization}")
        logging.info(f"  HCP_PROJECT: {self.config.project}")
        logging.info(f"  HCP_VAULT_SECRETS_APP: {self.config.app_name}")
        logging.info("")
        logging.info("To use the HCP CLI with this application:")
        logging.info(f"  export HCP_CLIENT_ID='{self.config.client_id}'")
        logging.info(f"  export HCP_CLIENT_SECRET='{self.config.client_secret}'")
        logging.info(f"  hcp vault-secrets secrets list --app={self.config.app_name}")
        logging.info("")
        logging.info("For more information:")
        logging.info("  https://developer.hashicorp.com/hcp/docs/vault-secrets")

    def run_setup(self) -> bool:
        """Run the complete setup process."""
        steps = [
            ("Authenticating with HCP", self.cli.authenticate),
            ("Setting up application", self.setup_application),
        ]

        for step_name, step_func in steps:
            logging.info(f"Step: {step_name}")
            if not step_func():
                logging.error(f"Setup failed at step: {step_name}")
                return False
            logging.info("")

        self.print_summary()
        return True


def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Set up HCP Vault Secrets for OpenShift installation workflows",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using Service Principal
  %(prog)s --organization myorg --project myproject --client-id abc123 --client-secret xyz789

  # Using environment variables
  export HCP_CLIENT_ID=abc123
  export HCP_CLIENT_SECRET=xyz789
  %(prog)s --organization myorg --project myproject

  # Custom application name
  %(prog)s --organization myorg --project myproject --app-name my-openshift-secrets

  # Dry run mode
  %(prog)s --organization myorg --project myproject --dry-run
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
        '--client-id',
        help='HCP Service Principal Client ID (required)'
    )
    parser.add_argument(
        '--client-secret',
        help='HCP Service Principal Client Secret (required)'
    )
    parser.add_argument(
        '-a', '--app-name',
        default='openshift-secrets',
        help='HCP Vault Secrets application name (default: openshift-secrets)'
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

    return parser.parse_args()


def main():
    """Main function."""
    args = parse_arguments()

    # Setup logging early
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Create configuration
    config = HCPVaultSecretsConfig(
        organization=args.organization or "",
        project=args.project or "",
        client_id=args.client_id or os.getenv('HCP_CLIENT_ID', ''),
        client_secret=args.client_secret or os.getenv('HCP_CLIENT_SECRET', ''),
        app_name=args.app_name,
        dry_run=args.dry_run,
        verbose=args.verbose
    )

    # Initialize setup
    setup = HCPVaultSecretsSetup(config)

    # Validate configuration
    if not setup.validate_config():
        sys.exit(1)

    # Display configuration
    logging.info("HCP Vault Secrets Setup Configuration:")
    logging.info(f"  Organization: {config.organization}")
    logging.info(f"  Project: {config.project}")
    logging.info(f"  Application: {config.app_name}")
    logging.info(f"  Authentication: Service Principal")
    logging.info(f"  Dry Run: {config.dry_run}")
    logging.info("")

    if config.dry_run:
        logging.info("DRY RUN MODE - No changes will be made")
        logging.info("")

    # Run the complete setup
    if not setup.run_setup():
        sys.exit(1)


if __name__ == '__main__':
    main()
