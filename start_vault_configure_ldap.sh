#!/bin/bash

# Start Vault in development mode with a predefined root token for simplicity
# WARNING: Running Vault in development mode is insecure and not recommended for production environments
vault server -dev -config=vault-config.hcl -dev-root-token-id="root" &

sleep 5

# Configuration variables for Vault
export VAULT_ADDR='https://127.0.0.1:8300'
export VAULT_TOKEN='root'
export VAULT_SKIP_VERIFY=true

# OpenLDAP configuration variables - policy store
export OPENLDAP_URL='ps8:1389' # OpenLDAP server address
export USERNAME='cn=admin,ou=Special Accounts,ou=siteminder,o=demo,c=us' # Bind DN (Distinguished Name)
export PASSWORD='password' # Bind DN password

# OpenLDAP configuration variables - user store
export USTORE_OPENLDAP_URL='ps8:2389' # OpenLDAP server address
export USTORE_USERNAME='uid=jdoe,ou=people,o=demo,c=us' # Bind DN (Distinguished Name)
export USTORE_PASSWORD='password' # Bind DN password

vault login -tls-skip-verify root 

# Enable the LDAP secrets engine in Vault
vault secrets enable ldap
vault secrets enable -path=ustore-ldap ldap


vault auth enable cert

# Configure the LDAP secrets engine
vault write ldap/config \
    binddn="$USERNAME" \
    bindpass="$PASSWORD" \
    url="ldap://$OPENLDAP_URL"

vault write ustore-ldap/config \
    binddn="$USTORE_USERNAME" \
    bindpass="$USTORE_PASSWORD" \
    url="ldap://$USTORE_OPENLDAP_URL"

# Create a static role in the LDAP secrets engine
# This role is associated with a specific LDAP entry and will have its password rotated according to the specified rotation period - user store
vault write ldap/static-role/pstore \
    dn='cn=admin2,ou=Special Accounts,ou=siteminder,o=demo,c=us' \
    username='admin2' \
    rotation_period="15m"

vault write ustore-ldap/static-role/ustore \
    dn='uid=btaylor,ou=people,o=demo,c=us' \
    username='btaylor' \
    rotation_period="15m"

# Note: Ensure that the LDAP server is reachable at the specified OPENLDAP_URL
# and that the credentials for the binddn are correct and have sufficient permissions.

vault policy write ldap-cred-policy ldap-cred-policy.hcl

vault write auth/cert/certs/web     \
    display_name=web     \
    policies=web,prod,ldap-cred-policy     \
    certificate=@./sample_key_pairs/certificate.pem     \
    ttl=3600