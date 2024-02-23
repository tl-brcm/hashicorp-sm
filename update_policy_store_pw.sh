#!/bin/bash

# Path to the LDAP credentials in Vault
LDAP_CRED_PATH="ldap/static-cred/pstore"

# Retrieve the new password from HashiCorp Vault
newPassword=$(vault read --format=json $LDAP_CRED_PATH | jq -r ".data.password")

# Check if newPassword was successfully retrieved
if [ -z "$newPassword" ]; then
    echo "Failed to retrieve new password from Vault."
    exit 1
fi

# Use sed to replace the AdminPW line in the policy_store.reg file
sed "s/\"AdminPW\"=\"[^\"]*\"/\"AdminPW\"=\"$newPassword\"/" policy_store.reg > policy_store_temp.reg

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
