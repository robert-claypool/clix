#!/usr/bin/env bash

# Description: Open the AWS Web Console for the active Leapp session.
# Usage: oplyn.sh [--help]

SCRIPT_NAME=$(basename "$0")

# Function to display help message
show_help() {
    echo "Usage: $SCRIPT_NAME [--help]"
    echo
    echo "Options:"
    echo "  --help    Display this help message."
    echo
    echo "Description:"
    echo "  Opens the AWS Web Console for the currently active Leapp session."
    echo "  If an active session is found, the script will prompt for confirmation"
    echo "  before opening the console in your default web browser."
    echo
    echo "Example:"
    echo "  $SCRIPT_NAME"
}

# Function to URL-encode a string
urlencode() {
    local data
    data=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$1'''))")
    echo "$data"
}

# Function to open AWS Web Console using existing session credentials
open_aws_console() {
    # Generate temporary credentials using Leapp
    if ! CREDENTIALS_JSON=$(leapp session generate "$SESSION_ID" 2>/dev/null); then
        echo "Error: Failed to generate temporary credentials using 'leapp session generate'."
        exit 1
    fi

    AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS_JSON" | jq -r '.AccessKeyId')
    AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS_JSON" | jq -r '.SecretAccessKey')
    AWS_SESSION_TOKEN=$(echo "$CREDENTIALS_JSON" | jq -r '.SessionToken')

    # Check if AWS credentials are available
    if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$AWS_SESSION_TOKEN" ]]; then
        echo "Error: AWS temporary credentials not found."
        echo "Please ensure you have an active session in Leapp GUI."
        exit 1
    fi

    # Create the session JSON
    SESSION_JSON=$(printf '{"sessionId":"%s","sessionKey":"%s","sessionToken":"%s"}' \
        "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_SESSION_TOKEN")

    # URL-encode the session JSON
    URL_ENCODED_SESSION_JSON=$(urlencode "$SESSION_JSON")

    # Get the sign-in token
    SIGNIN_TOKEN_JSON=$(curl -s "https://signin.aws.amazon.com/federation?Action=getSigninToken&Session=$URL_ENCODED_SESSION_JSON")

    SIGNIN_TOKEN=$(echo "$SIGNIN_TOKEN_JSON" | jq -r '.SigninToken')

    if [[ -z "$SIGNIN_TOKEN" ]]; then
        echo "Error: Failed to get SigninToken."
        exit 1
    fi

    # Construct the console URL
    DESTINATION=$(urlencode "https://console.aws.amazon.com/console/home")
    CONSOLE_URL="https://signin.aws.amazon.com/federation?Action=login&Issuer=Leapp&Destination=$DESTINATION&SigninToken=$SIGNIN_TOKEN"

    # Open the console URL in the default browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$CONSOLE_URL"
    elif command -v open &> /dev/null; then
        open "$CONSOLE_URL"
    else
        echo "Error: Could not detect the web browser command."
        exit 1
    fi

    echo "AWS Web Console opened successfully."
}

# Display help message if --help is passed
if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if 'jq' is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it and try again."
    echo "You can install 'jq' using your package manager. For example:"
    echo "  Debian/Ubuntu: sudo apt-get install jq"
    echo "  macOS (Homebrew): brew install jq"
    exit 1
fi

# Check if 'leapp' CLI is installed
if ! command -v leapp &> /dev/null; then
    echo "Error: 'leapp' command not found. Please ensure Leapp CLI is installed and in your PATH."
    exit 1
fi

# Retrieve the list of sessions in JSON format with extended output
if ! SESSIONS_JSON=$(leapp session list -x --output json 2>/dev/null); then
    echo "Error: Failed to retrieve sessions using 'leapp session list -x'."
    exit 1
fi

# Use 'jq' to find the active session
ACTIVE_SESSION=$(echo "$SESSIONS_JSON" | jq '.[] | select(.status == "active")')

# Check if an active session exists
if [[ -z "$ACTIVE_SESSION" ]]; then
    echo "No active session found."
    exit 1
fi

# Extract the Session ID and Session Name
SESSION_ID=$(echo "$ACTIVE_SESSION" | jq -r '.id')
SESSION_NAME=$(echo "$ACTIVE_SESSION" | jq -r '.sessionName')

# Prompt the user for confirmation
printf "Session '%s' will be opened in your browser. Continue? (Y/n) " "$SESSION_NAME"
read -r RESPONSE

# Set default response to 'Y' if the user presses enter
RESPONSE=${RESPONSE:-Y}

# Check the user's response
if [[ "$RESPONSE" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    open_aws_console
else
    echo "Operation aborted by the user."
    exit 0
fi
