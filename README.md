# HashiCorp SiteMinder LDAP integration script

This repository contains scripts designed to streamline the process of integrating HashiCorp Vault with LDAP for secure management of credentials and policy store passwords. These scripts automate the setup of the LDAP secret engine in Vault, and update user and policy store passwords with credentials stored in Vault.

## Contents

- [Start HashiCorp and Configure LDAP Secret Engine](#start-hashicorp-and-configure-ldap-secret-engine)
- [Update User Store Password from HashiCorp Vault](#update-user-store-password-from-hashicorp-vault)
- [Update Policy Store Password from HashiCorp Vault](#update-policy-store-password-from-hashicorp-vault)

### Prerequisites

Before running these scripts, ensure you have the following installed:

- HashiCorp Vault
- jq (Command-line JSON processor)
- Access to an LDAP server for integration

## Start HashiCorp and Configure LDAP Secret Engine

`start_vault_configure_ldap.sh`

This script starts the HashiCorp Vault server in development mode and configures the LDAP secret engine. It sets up the connection to an LDAP server, enabling secure authentication and management of LDAP credentials through Vault.

IMPORTANT: Do not run vault server in dev model for production use. This is for POC purpose and if you already have a vault running in prod mode, you dont have to run `start_vault_configure_ldap` script. 

### Usage

Run the script with no arguments:

```bash
./start_vault_configure_ldap.sh
```

## Test Vault login
`test_vault_cert_login.sh`

Update the script with the certifcate path and vault URL, and test login. This step is required before moving to next steps. Once it's working, copy the variable values to the scripts that you need to run. 



## Update User Store Password from HashiCorp Vault

`update_user_store_pw.sh`

Automatically retrieves the latest user store password from HashiCorp Vault and updates the configuration accordingly. This script ensures that the user store password is kept secure and rotated according to best practices.

Open the script to modify the variable based on your need, e.g. siteminder url, username, password, udo name, udo user and password etc. 

NOTE: The script need to be run whenever the hashicorp password is rollover. You can integrate this to a cron job that poll vault changes with certain frequency, or subscribe to vault event and trigger the script if you are using enterpise edition. 

### Usage

Ensure you have the correct path to your LDAP credentials in Vault defined in the script, then run:

```bash
./update_user_store_pw.sh
```

## Update Policy Store Password from HashiCorp Vault

`update_policy_store_pw.sh`

Fetches the new policy store password from HashiCorp Vault and applies it to the policy store configuration. This script facilitates the secure and automated management of policy store passwords.

Open the script to modify the variable based on your need, e.g. siteminder url, username, password, udo name, udo user and password etc. 

Make sure the policy store admin user in your registry is the same as the one from the password vault. 

NOTE: Run this script before the start up of policy server. 

### Usage

Modify the script to include the correct path to your policy store credentials in Vault. Execute the script by running:

```bash
./update_policy_store_pw.sh
```
