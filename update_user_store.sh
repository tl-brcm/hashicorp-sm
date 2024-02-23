#!/bin/bash

# Variables for easy customization
#!/bin/bash

# Host name for all API requests
HOST="https://ps2.k3s.demo"

# API Endpoints
LOGIN_ENDPOINT="/ca/api/sso/services/login/v1/token"
UPDATE_PASSWORD_ENDPOINT="/ca/api/sso/services/policy/v1/SmUserDirectories/udo1%20openldap"

# Complete URL construction
LOGIN_URL="${HOST}${LOGIN_ENDPOINT}"
UPDATE_PASSWORD_URL="${HOST}${UPDATE_PASSWORD_ENDPOINT}"
USER_DIR_NAME="udo1%20openldap" # User directory name, URL encoded if necessary

LDAP_CRED_PATH="ldap/static-cred/learn"
LDAP_USER="cn=udo_admin, ou=People,dc=example,dc=com"
ACCEPT_HEADER="application/ecmascript"

# Username and Password for the Authorization header
USER="siteminder:P@ssw0rd1" # Replace 'siteminder:P@ssw0rd1' with actual username:password

# Base64 encode the username:password and create the Authorization header
AUTHORIZATION_HEADER="Basic $(echo -n $USER | base64)"

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

# Get the latest password from HashiCorp Vault
LDAP_PASSWORD=$(vault read --format=json $LDAP_CRED_PATH | jq -r ".data.password")

# Update the password in Siteminder
UPDATE_RESPONSE=$(curl --location --request PUT "$UPDATE_PASSWORD_URL" \
--header "Accept: $ACCEPT_HEADER" \
--header "Content-Type: application/json" \
--header "Authorization: Bearer $SESSION_KEY" \
--data "{
    \"Username\": \"$LDAP_USER\",
    \"Password\": \"$LDAP_PASSWORD\"
}")

echo "Password update response: $UPDATE_RESPONSE"
