#!/usr/bin/env bash

# Check if op is installed
if ! command -v op &> /dev/null; then
    echo "op CLI is not installed. Please install it first."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it first."
    exit 1
fi

# Accept tag as an argument
TAG="$1"

if [ -z "$TAG" ]; then
    echo "No tag was provided, showing tagless items only."
fi

# Get the list of accounts
accounts_json=$(op account list --format json)

# Check if accounts are available
if [ -z "$accounts_json" ] || [ "$accounts_json" == "[]" ]; then
    echo "No accounts found. Please sign in to your 1Password account using 'op signin'."
    exit 1
fi

# Parse account emails and account UUIDs using while loops
account_emails=()
while IFS= read -r line; do
    account_emails+=("$line")
done < <(echo "$accounts_json" | jq -r '.[].email')

account_uuids=()
while IFS= read -r line; do
    account_uuids+=("$line")
done < <(echo "$accounts_json" | jq -r '.[].account_uuid')

# List accounts
echo "Available Accounts:"
for i in "${!account_emails[@]}"; do
    echo "$((i+1)). ${account_emails[$i]}"
done

# Prompt user to select an account
read -p "Select an account by number: " account_choice

# Validate input
if ! [[ "$account_choice" =~ ^[0-9]+$ ]] || [ "$account_choice" -lt 1 ] || [ "$account_choice" -gt "${#account_emails[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

selected_account_uuid="${account_uuids[$((account_choice-1))]}"

# Get the list of vaults in the selected account
vaults_json=$(op vault list --account "$selected_account_uuid" --format json)

# Check if vaults are available
if [ -z "$vaults_json" ] || [ "$vaults_json" == "[]" ]; then
    echo "No vaults found in the selected account."
    exit 1
fi

# Parse vault IDs and names using while loops
vault_ids=()
while IFS= read -r line; do
    vault_ids+=("$line")
done < <(echo "$vaults_json" | jq -r '.[].id')

vault_names=()
while IFS= read -r line; do
    vault_names+=("$line")
done < <(echo "$vaults_json" | jq -r '.[].name')

# List vaults
echo "Available Vaults in account '${account_emails[$((account_choice-1))]}':"
for i in "${!vault_names[@]}"; do
    echo "$((i+1)). ${vault_names[$i]}"
done

# Prompt user to select a vault
read -p "Select a vault by number: " vault_choice

# Validate input
if ! [[ "$vault_choice" =~ ^[0-9]+$ ]] || [ "$vault_choice" -lt 1 ] || [ "$vault_choice" -gt "${#vault_names[@]}" ]]; then
    echo "Invalid selection."
    exit 1
fi

selected_vault="${vault_ids[$((vault_choice-1))]}"

# Get the list of items in the selected vault
if [ -n "$TAG" ]; then
    items_json=$(op item list --vault "$selected_vault" --account "$selected_account_uuid" --tags "$TAG" --format json)
else
    # Get items without any tags
    items_json=$(op item list --vault "$selected_vault" --account "$selected_account_uuid" --format json)
    # Filter items with no tags
    items_json=$(echo "$items_json" | jq '[.[] | select(.tags == null or .tags == [])]')
fi

# Check if items are available
if [ -z "$items_json" ] || [ "$items_json" == "[]" ]; then
    if [ -n "$TAG" ]; then
        echo "No items with tag '$TAG' found in the selected vault."
    else
        echo "No tagless items found in the selected vault."
    fi
    exit 1
fi

# Parse item IDs and titles using while loops
item_ids=()
while IFS= read -r line; do
    item_ids+=("$line")
done < <(echo "$items_json" | jq -r '.[].id')

item_titles=()
while IFS= read -r line; do
    item_titles+=("$line")
done < <(echo "$items_json" | jq -r '.[].title')

# List items
if [ -n "$TAG" ]; then
    echo "Items in vault '${vault_names[$((vault_choice-1))]}' with tag '$TAG':"
else
    echo "Tagless items in vault '${vault_names[$((vault_choice-1))]}':"
fi
for i in "${!item_titles[@]}"; do
    echo "$((i+1)). ${item_titles[$i]}"
done

# Prompt user to select an item
read -p "Select an item by number: " item_choice

# Validate input
if ! [[ "$item_choice" =~ ^[0-9]+$ ]] || [ "$item_choice" -lt 1 ] || [ "$item_choice" -gt "${#item_titles[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

selected_item="${item_ids[$((item_choice-1))]}"

# Get the password field of the selected item
password_json=$(op item get "$selected_item" --vault "$selected_vault" --account "$selected_account_uuid" --fields label=password --format json)

# Extract the password
password=$(echo "$password_json" | jq -r '.value')

if [ -z "$password" ] || [ "$password" == "null" ]; then
    echo "Password field not found for the selected item."
    exit 1
fi

# Copy password to clipboard
if command -v pbcopy &> /dev/null; then
    # macOS
    echo -n "$password" | pbcopy
    echo "Password for item '${item_titles[$((item_choice-1))]}' has been copied to the clipboard."
elif command -v xclip &> /dev/null; then
    # Linux with xclip
    echo -n "$password" | xclip -selection clipboard
    echo "Password for item '${item_titles[$((item_choice-1))]}' has been copied to the clipboard."
elif command -v xsel &> /dev/null; then
    # Linux with xsel
    echo -n "$password" | xsel --clipboard --input
    echo "Password for item '${item_titles[$((item_choice-1))]}' has been copied to the clipboard."
else
    echo "No clipboard utility found. Please install 'pbcopy' (macOS) or 'xclip'/'xsel' (Linux)."
    echo "Password is:"
    echo "$password"
fi
