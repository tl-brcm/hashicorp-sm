#!/bin/bash

# Variables for Vault
VAULT_ADDR="https://192.168.1.203:8300"
CERT_PATH="./sample_key_pairs/certificate.pem"
KEY_PATH="./sample_key_pairs/private_key.pem"
LDAP_CRED_PATH="ldap/static-cred/pstore"
SITEMINDER_HOME="/opt/CA/siteminder"

# Make sure the smprofile.ksh is sourced. if not do that. 
. $SITEMINDER_HOME/smprofile.ksh
if [ $? -ne 0 ]; then
    echo "Not able to source the siteminder profile. Make sure the file existgs"
    exit 1
fi

# Function to authenticate with Vault using certificate and get a token
vault_login() {
    local vault_login_url="${VAULT_ADDR}/v1/auth/cert/login"
    local vault_login_response=$(curl --insecure --cert $CERT_PATH --key $KEY_PATH \
        --request POST \
        --data '{"name": "web"}' \
        $vault_login_url)

    local vault_token=$(echo $vault_login_response | jq -r '.auth.client_token')

    if [ -n "$vault_token" ]; then
        echo "$vault_token"
    else
        echo "Failed to obtain Vault token" >&2
        exit 1
    fi
}

# Authenticate with Vault and get a token
VAULT_TOKEN=$(vault_login)

# Retrieve the new password from HashiCorp Vault using the token
vault_secret_url="${VAULT_ADDR}/v1/${LDAP_CRED_PATH}"
newPassword=$(curl --insecure --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $vault_secret_url | jq -r ".data.password")

# Check if newPassword was successfully retrieved
if [ -z "$newPassword" ]; then
    echo "Failed to retrieve new password from Vault."
    exit 1
fi


# Make a backup of the sm.registry
cp $SITEMINDER_HOME/registry/sm.registry $SITEMINDER_HOME/registry/sm.registry.bak

# This will write the password to the sm.retistry file. 
smldapsetup reg -w$newPassword

passwordEncrypted="{RC2}"$(grep -A5 LdapPolicyStore $SITEMINDER_HOME/registry/sm.registry | grep AdminPW | grep -oP '(?<=\{RC2\})[^; ]+')
if [ $? -ne 0 ]; then
    echo "Not able to get encrypted password from sm.registry file. Please check the file"
    exit 1
fi

escapedPassword=$(printf '%s\n' "$passwordEncrypted" | sed -e 's/[\/&]/\\&/g')

# Move the backup file back to the original one because not using LDAP password. 
cp $SITEMINDER_HOME/registry/sm.registry.bak $SITEMINDER_HOME/registry/sm.registry

# Use sed to replace the AdminPW line in the policy_store.reg file
sed  "s/\[new_password\]/$escapedPassword/" policy_store.reg > policy_store_temp.reg

# Check if sed command was successful
if [ $? -ne 0 ]; then
    echo "Failed to update the AdminPW in the policy_store.reg file."
    exit 1
fi

# Run smregimport to update the policy store password
smregimport -f policy_store_temp.reg

# Check if smregimport command was successful
if [ $? -ne 0 ]; then
    echo "smregimport command failed."
    # Even if smregimport fails, we proceed to delete the temp file for security
fi

# Securely delete the policy_store_temp.reg file for security purposes
# This will happen no matter whether the previous step is successful or not
rm -f policy_store_temp.reg

# Final success message
echo "Policy store password update process completed."
