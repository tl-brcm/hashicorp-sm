#!/bin/bash

# Variables for easy customization
HOST="https://ps8:8443"

USER_DIR_NAME="udo-local" # User directory name, URL encoded if necessary

# API Endpoints
LOGIN_ENDPOINT="/ca/api/sso/services/login/v1/token"
UPDATE_PASSWORD_ENDPOINT="/ca/api/sso/services/policy/v1/SmUserDirectories/"$USER_DIR_NAME

# Complete URL construction
LOGIN_URL="${HOST}${LOGIN_ENDPOINT}"
UPDATE_PASSWORD_URL="${HOST}${UPDATE_PASSWORD_ENDPOINT}"

# Modify this for Oracle database credentials
ORACLE_CRED_PATH="database/creds/my-role"
ORACLE_USER="btaylor"
ACCEPT_HEADER="application/ecmascript"

# Username and Password for the Authorization header
SM_ADMIN_USER="apiadmin:password" # Replace 'apiadmin:password' with actual username:password

# Base64 encode the username:password and create the Authorization header
AUTHORIZATION_HEADER="Basic $(echo -n $SM_ADMIN_USER | base64)"

# Login to Siteminder to get the session key
SESSION_RESPONSE=$(curl --location --request POST "$LOGIN_URL" \
--header "Accept: $ACCEPT_HEADER" \
--header "Authorization: $AUTHORIZATION_HEADER" \
--data '' -k)

# Extract session key and set it as a variable
SESSION_KEY=$(echo $SESSION_RESPONSE | jq -r '.sessionkey')

if [ -n "$SESSION_KEY" ]; then
  echo "Session key obtained successfully"
else
  echo "Failed to obtain session key"
  exit 1
fi

# Authenticate with Vault using certificate
VAULT_ADDR="https://127.0.0.1:8300"
VAULT_LOGIN_URL="${VAULT_ADDR}/v1/auth/cert/login"
CERT_PATH="./sample_key_pairs/certificate.pem"
KEY_PATH="./sample_key_pairs/private_key.pem"

VAULT_LOGIN_RESPONSE=$(curl --insecure --cert $CERT_PATH --key $KEY_PATH \
    --request POST \
    --data '{"name": "web"}' \
    $VAULT_LOGIN_URL)

# Extract Vault token
VAULT_TOKEN=$(echo $VAULT_LOGIN_RESPONSE | jq -r '.auth.client_token')

if [ -n "$VAULT_TOKEN" ]; then
  echo "Vault token obtained successfully"
else
  echo "Failed to obtain Vault token"
  exit 1
fi

# Get the latest Oracle database credentials from HashiCorp Vault
VAULT_SECRET_URL="${VAULT_ADDR}/v1/${ORACLE_CRED_PATH}"
ORACLE_CREDENTIALS=$(curl --insecure --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_SECRET_URL)

ORACLE_USER=$(echo $ORACLE_CREDENTIALS | jq -r ".data.username")
ORACLE_PASSWORD=$(echo $ORACLE_CREDENTIALS | jq -r ".data.password")

if [ -n "$ORACLE_USER" ] && [ -n "$ORACLE_PASSWORD" ]; then
  echo "Oracle credentials obtained successfully"
else
  echo "Failed to obtain Oracle credentials"
  exit 1
fi

# Update the password in Siteminder
UPDATE_RESPONSE=$(curl --location --request PUT "$UPDATE_PASSWORD_URL" \
--header "Accept: $ACCEPT_HEADER" \
--header "Content-Type: application/json" \
--header "Authorization: Bearer $SESSION_KEY" \
--data "{
    \"Username\": \"$ORACLE_USER\",
    \"Password\": \"$ORACLE_PASSWORD\"
}" -k)

echo "Password update response: $UPDATE_RESPONSE"
