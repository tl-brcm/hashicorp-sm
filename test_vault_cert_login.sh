#!/bin/bash

# Variables for Vault
VAULT_ADDR="https://127.0.0.1:8300"
CERT_PATH="./sample_key_pairs/certificate.pem"
KEY_PATH="./sample_key_pairs/private_key.pem"

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

VAULT_TOKEN=$(vault_login)

echo $VAULT_TOKEN