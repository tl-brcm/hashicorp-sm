#!/bin/bash

# Start Vault in development mode with a predefined root token for simplicity
# WARNING: Running Vault in development mode is insecure and not recommended for production environments
vault server -dev -dev-root-token-id root &

# Configuration variables for Vault
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# OpenLDAP configuration variables
export OPENLDAP_URL='192.168.1.240:389' # OpenLDAP server address
export USERNAME='cn=admin,dc=example,dc=com' # Bind DN (Distinguished Name)
export PASSWORD='Not@SecurePassw0rd' # Bind DN password

# Enable the LDAP secrets engine in Vault
vault secrets enable ldap

# Configure the LDAP secrets engine
vault write ldap/config \
    binddn="$USERNAME" \
    bindpass="$PASSWORD" \
    url="ldap://$OPENLDAP_URL"

# Create a static role in the LDAP secrets engine
# This role is associated with a specific LDAP entry and will have its password rotated according to the specified rotation period
vault write ldap/static-role/learn \
    dn='cn=udo_admin,ou=People,dc=example,dc=com' \
    username='udo_admin' \
    rotation_period="5m"

# Note: Ensure that the LDAP server is reachable at the specified OPENLDAP_URL
# and that the credentials for the binddn are correct and have sufficient permissions.
