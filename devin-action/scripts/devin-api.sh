#!/bin/bash
# =============================================================================
# Devin API Shell Script
# =============================================================================
# 
# DESCRIPTION:
#   This script provides a command-line interface to interact with the Devin API.
#   It is designed to be used as part of a GitHub Action, enabling automated
#   session management, secrets handling, knowledge base operations, and
#   playbook management directly from GitHub workflows.
#
# USAGE:
#   ./devin-api.sh <action> <api-key> [parameters...]
#
# SUPPORTED ACTIONS:
#   Session Management:
#     - create-session    : Create a new Devin session with a task prompt
#     - send-message      : Send a message to an existing session
#     - get-session       : Retrieve details about a specific session
#     - list-sessions     : List all available sessions
#     - upload-files      : Upload files to a session
#     - update-tags       : Update tags on a session
#
#   Secrets Management:
#     - list-secrets      : List all stored secrets
#     - create-secret     : Create a new secret
#     - delete-secret     : Delete an existing secret
#
#   Knowledge Management:
#     - list-knowledge    : List all knowledge entries
#     - create-knowledge  : Create a new knowledge entry
#     - update-knowledge  : Update an existing knowledge entry
#     - delete-knowledge  : Delete a knowledge entry
#
#   Playbooks Management:
#     - list-playbooks    : List all playbooks
#     - create-playbook   : Create a new playbook
#     - get-playbook      : Get details of a specific playbook
#     - update-playbook   : Update an existing playbook
#     - delete-playbook   : Delete a playbook
#
# DEPENDENCIES:
#   - curl    : For making HTTP requests to the Devin API
#   - jq      : For JSON parsing and manipulation
#   - bash    : Shell interpreter (version 4.0+)
#
# ENVIRONMENT:
#   This script expects to run in a GitHub Actions environment where
#   $GITHUB_OUTPUT is available for setting action outputs.
#
# AUTHOR: Sam Fertig (@samfert-codeium)
# LICENSE: Apache-2.0
# =============================================================================

# Exit immediately if any command fails
# This ensures the script stops on errors rather than continuing with invalid state
set -e

# =============================================================================
# PARAMETER DEFINITIONS
# =============================================================================
# Parameters are passed as positional arguments from the GitHub Action
# The order matches the inputs defined in action.yml

# ACTION: The API operation to perform (required)
# Valid values: create-session, send-message, get-session, list-sessions,
#               upload-files, update-tags, list-secrets, create-secret,
#               delete-secret, list-knowledge, create-knowledge, update-knowledge,
#               delete-knowledge, list-playbooks, create-playbook, get-playbook,
#               update-playbook, delete-playbook
ACTION="$1"

# API_KEY: Devin API authentication key (required)
# Should be stored as a GitHub secret and passed via ${{ secrets.DEVIN_API_KEY }}
API_KEY="$2"

# PROMPT: Task description for Devin (required for create-session)
# This is the main instruction that Devin will follow
PROMPT="$3"

# SESSION_ID: Unique identifier for a Devin session
# Required for: send-message, get-session, upload-files, update-tags
SESSION_ID="$4"

# MESSAGE: Text message to send to Devin (required for send-message)
MESSAGE="$5"

# SNAPSHOT_ID: ID of a machine snapshot to use (optional for create-session)
# Allows starting a session from a pre-configured machine state
SNAPSHOT_ID="$6"

# UNLISTED: Whether the session should be unlisted (optional, default: false)
# Unlisted sessions don't appear in public session lists
UNLISTED="$7"

# IDEMPOTENT: Enable idempotent session creation (optional, default: false)
# When true, returns existing session if one with same prompt exists
IDEMPOTENT="$8"

# MAX_ACU_LIMIT: Maximum ACU (Autonomous Compute Units) limit for the session
# Controls the computational resources allocated to the session
MAX_ACU_LIMIT="$9"

# SECRET_IDS: Comma-separated list of secret IDs to attach to the session
# These secrets will be available to Devin during the session
SECRET_IDS="${10}"

# KNOWLEDGE_IDS: Comma-separated list of knowledge IDs to attach to the session
# Knowledge entries provide context and information to Devin
KNOWLEDGE_IDS="${11}"

# TAGS: Comma-separated list of tags for categorizing sessions
# Used for create-session and update-tags actions
TAGS="${12}"

# TITLE: Custom title for the session (optional for create-session)
# Provides a human-readable name for the session
TITLE="${13}"

# FILE_PATH: Local path to a file to upload (required for upload-files)
FILE_PATH="${14}"

# SECRET_ID: Unique identifier for a secret (required for delete-secret)
SECRET_ID="${15}"

# SECRET_NAME: Name for a new secret (required for create-secret)
SECRET_NAME="${16}"

# SECRET_VALUE: Value for a new secret (required for create-secret)
# Should be passed securely via GitHub secrets
SECRET_VALUE="${17}"

# KNOWLEDGE_ID: Unique identifier for a knowledge entry
# Required for: update-knowledge, delete-knowledge
KNOWLEDGE_ID="${18}"

# KNOWLEDGE_NAME: Name for a knowledge entry (for create/update-knowledge)
KNOWLEDGE_NAME="${19}"

# KNOWLEDGE_CONTENT: Content of a knowledge entry (for create/update-knowledge)
KNOWLEDGE_CONTENT="${20}"

# PLAYBOOK_ID: Unique identifier for a playbook
# Required for: get-playbook, update-playbook, delete-playbook
PLAYBOOK_ID="${21}"

# PLAYBOOK_NAME: Name for a playbook (for create/update-playbook)
PLAYBOOK_NAME="${22}"

# PLAYBOOK_CONTENT: Content of a playbook (for create/update-playbook)
PLAYBOOK_CONTENT="${23}"

# =============================================================================
# CONFIGURATION
# =============================================================================

# BASE_URL: The base URL for the Devin API
# All API endpoints are relative to this URL
BASE_URL="https://api.devin.ai/v1"

# =============================================================================
# SESSION MANAGEMENT FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# create_session()
# -----------------------------------------------------------------------------
# Creates a new Devin session with the specified parameters.
#
# This function builds a JSON payload dynamically based on which optional
# parameters are provided, then sends a POST request to create the session.
#
# Required inputs:
#   - PROMPT: The task description for Devin
#
# Optional inputs:
#   - SNAPSHOT_ID: Machine snapshot to use
#   - UNLISTED: Whether session should be unlisted
#   - IDEMPOTENT: Enable idempotent creation
#   - MAX_ACU_LIMIT: Maximum ACU limit
#   - SECRET_IDS: Comma-separated secret IDs
#   - KNOWLEDGE_IDS: Comma-separated knowledge IDs
#   - TAGS: Comma-separated tags
#   - TITLE: Custom session title
#
# Outputs (written to $GITHUB_OUTPUT):
#   - session-id: The unique ID of the created session
#   - session-url: URL to access the session in the Devin UI
#   - is-new-session: Boolean indicating if a new session was created
#   - response: The full JSON response from the API
# -----------------------------------------------------------------------------
function create_session() {
    # Initialize an empty JSON object for the request payload
    local payload_obj='{}'
    
    # Add the required prompt parameter to the payload
    # Using jq's --arg flag safely escapes the string value
    payload_obj=$(echo "$payload_obj" | jq --arg prompt "$PROMPT" '. + {prompt: $prompt}')
    
    # Add optional snapshot_id if provided
    # This allows starting from a pre-configured machine state
    if [ -n "$SNAPSHOT_ID" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg snapshot_id "$SNAPSHOT_ID" '. + {snapshot_id: $snapshot_id}')
    fi
    
    # Add unlisted flag if set to true
    # Unlisted sessions won't appear in public session listings
    if [ "$UNLISTED" = "true" ]; then
        payload_obj=$(echo "$payload_obj" | jq '. + {unlisted: true}')
    fi
    
    # Add idempotent flag if set to true
    # Enables returning existing session instead of creating duplicate
    if [ "$IDEMPOTENT" = "true" ]; then
        payload_obj=$(echo "$payload_obj" | jq '. + {idempotent: true}')
    fi
    
    # Add max_acu_limit if provided
    # Using --argjson to pass as a number, not a string
    if [ -n "$MAX_ACU_LIMIT" ]; then
        payload_obj=$(echo "$payload_obj" | jq --argjson max_acu_limit "$MAX_ACU_LIMIT" '. + {max_acu_limit: $max_acu_limit}')
    fi
    
    # Process comma-separated secret IDs into a JSON array
    # IFS=',' splits the string by commas into an array
    if [ -n "$SECRET_IDS" ]; then
        IFS=',' read -ra SECRET_ARRAY <<< "$SECRET_IDS"
        # Convert bash array to JSON array using jq
        # printf outputs each element on a new line, jq -R reads as raw strings,
        # and jq -s collects them into an array
        secret_ids_json=$(printf '%s\n' "${SECRET_ARRAY[@]}" | jq -R . | jq -s .)
        payload_obj=$(echo "$payload_obj" | jq --argjson secret_ids "$secret_ids_json" '. + {secret_ids: $secret_ids}')
    fi
    
    # Process comma-separated knowledge IDs into a JSON array
    if [ -n "$KNOWLEDGE_IDS" ]; then
        IFS=',' read -ra KNOWLEDGE_ARRAY <<< "$KNOWLEDGE_IDS"
        knowledge_ids_json=$(printf '%s\n' "${KNOWLEDGE_ARRAY[@]}" | jq -R . | jq -s .)
        payload_obj=$(echo "$payload_obj" | jq --argjson knowledge_ids "$knowledge_ids_json" '. + {knowledge_ids: $knowledge_ids}')
    fi
    
    # Process comma-separated tags into a JSON array
    if [ -n "$TAGS" ]; then
        IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
        tags_json=$(printf '%s\n' "${TAG_ARRAY[@]}" | jq -R . | jq -s .)
        payload_obj=$(echo "$payload_obj" | jq --argjson tags "$tags_json" '. + {tags: $tags}')
    fi
    
    # Add optional title if provided
    if [ -n "$TITLE" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg title "$TITLE" '. + {title: $title}')
    fi
    
    # Store the final payload
    local payload="$payload_obj"
    
    # Send POST request to create the session
    # -s: Silent mode (no progress meter)
    # -X POST: Use POST method
    # -H: Set headers for authorization and content type
    # -d: Send the JSON payload as request body
    response=$(curl -s -X POST "${BASE_URL}/sessions" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "${payload}")
    
    # Output the response for logging purposes
    echo "${response}"
    
    # Extract session_id from the JSON response using grep and cut
    # This approach avoids jq dependency for simple field extraction
    session_id=$(echo "${response}" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
    
    # Extract the session URL from the response
    session_url=$(echo "${response}" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    
    # Extract is_new_session flag (for idempotent requests)
    is_new=$(echo "${response}" | grep -o '"is_new_session":[^,}]*' | cut -d':' -f2)
    
    # Write outputs to GitHub Actions output file
    # These values can be accessed in subsequent workflow steps
    echo "session-id=${session_id}" >> $GITHUB_OUTPUT
    echo "session-url=${session_url}" >> $GITHUB_OUTPUT
    echo "is-new-session=${is_new}" >> $GITHUB_OUTPUT
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# send_message()
# -----------------------------------------------------------------------------
# Sends a message to an existing Devin session.
#
# This allows you to provide additional instructions or context to Devin
# after a session has been created.
#
# Required inputs:
#   - SESSION_ID: The ID of the target session
#   - MESSAGE: The message text to send
#
# Outputs:
#   - response: The full JSON response from the API
# -----------------------------------------------------------------------------
function send_message() {
    # Validate required parameters
    if [ -z "$SESSION_ID" ] || [ -z "$MESSAGE" ]; then
        echo "Error: session-id and message are required for send-message action"
        exit 1
    fi
    
    # Build JSON payload with the message
    # jq -n creates a new JSON object from scratch
    local payload=$(jq -n --arg message "$MESSAGE" '{message: $message}')
    
    # Send POST request to the session's message endpoint
    response=$(curl -s -X POST "${BASE_URL}/sessions/${SESSION_ID}/message" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# get_session()
# -----------------------------------------------------------------------------
# Retrieves details about a specific Devin session.
#
# Returns information including session status, messages, and metadata.
#
# Required inputs:
#   - SESSION_ID: The ID of the session to retrieve
#
# Outputs:
#   - response: The full JSON response containing session details
# -----------------------------------------------------------------------------
function get_session() {
    # Validate required parameter
    if [ -z "$SESSION_ID" ]; then
        echo "Error: session-id is required for get-session action"
        exit 1
    fi
    
    # Send GET request to retrieve session details
    response=$(curl -s -X GET "${BASE_URL}/sessions/${SESSION_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# list_sessions()
# -----------------------------------------------------------------------------
# Lists all Devin sessions associated with the API key.
#
# Returns an array of session objects with their basic information.
#
# Outputs:
#   - response: JSON array of session objects
# -----------------------------------------------------------------------------
function list_sessions() {
    # Send GET request to list all sessions
    response=$(curl -s -X GET "${BASE_URL}/sessions" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# upload_files()
# -----------------------------------------------------------------------------
# Uploads a file to an existing Devin session.
#
# The uploaded file will be available to Devin within the session context.
# Useful for providing code files, documentation, or other resources.
#
# Required inputs:
#   - SESSION_ID: The ID of the target session
#   - FILE_PATH: Local path to the file to upload
#
# Outputs:
#   - response: The API response confirming the upload
# -----------------------------------------------------------------------------
function upload_files() {
    # Validate required parameters
    if [ -z "$SESSION_ID" ] || [ -z "$FILE_PATH" ]; then
        echo "Error: session-id and file-path are required for upload-files action"
        exit 1
    fi
    
    # Verify the file exists before attempting upload
    if [ ! -f "$FILE_PATH" ]; then
        echo "Error: File not found: ${FILE_PATH}"
        exit 1
    fi
    
    # Send POST request with multipart form data
    # -F: Specifies form field with file upload (@prefix indicates file)
    response=$(curl -s -X POST "${BASE_URL}/sessions/${SESSION_ID}/attachments" \
        -H "Authorization: Bearer ${API_KEY}" \
        -F "file=@${FILE_PATH}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# update_tags()
# -----------------------------------------------------------------------------
# Updates the tags on an existing Devin session.
#
# Tags are useful for categorizing and filtering sessions.
#
# Required inputs:
#   - SESSION_ID: The ID of the target session
#   - TAGS: Comma-separated list of tags to set
#
# Outputs:
#   - response: The API response confirming the update
# -----------------------------------------------------------------------------
function update_tags() {
    # Validate required parameters
    if [ -z "$SESSION_ID" ] || [ -z "$TAGS" ]; then
        echo "Error: session-id and tags are required for update-tags action"
        exit 1
    fi
    
    # Convert comma-separated tags to JSON array
    IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
    tags_json=$(printf '%s\n' "${TAG_ARRAY[@]}" | jq -R . | jq -s .)
    local payload=$(jq -n --argjson tags "$tags_json" '{tags: $tags}')
    
    # Send PUT request to update the session's tags
    response=$(curl -s -X PUT "${BASE_URL}/sessions/${SESSION_ID}/tags" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# =============================================================================
# SECRETS MANAGEMENT FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# list_secrets()
# -----------------------------------------------------------------------------
# Lists all secrets stored in the Devin account.
#
# Returns metadata about secrets (not the actual values for security).
#
# Outputs:
#   - response: JSON array of secret metadata objects
# -----------------------------------------------------------------------------
function list_secrets() {
    # Send GET request to list all secrets
    response=$(curl -s -X GET "${BASE_URL}/secrets" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# create_secret()
# -----------------------------------------------------------------------------
# Creates a new secret in the Devin account.
#
# Secrets can be attached to sessions to provide sensitive credentials
# like API keys, passwords, or tokens.
#
# Required inputs:
#   - SECRET_NAME: A descriptive name for the secret
#   - SECRET_VALUE: The actual secret value (handle securely!)
#
# Outputs:
#   - response: The API response with the created secret's metadata
# -----------------------------------------------------------------------------
function create_secret() {
    # Validate required parameters
    if [ -z "$SECRET_NAME" ] || [ -z "$SECRET_VALUE" ]; then
        echo "Error: secret-name and secret-value are required for create-secret action"
        exit 1
    fi
    
    # Build JSON payload with secret name and value
    local payload=$(jq -n --arg name "$SECRET_NAME" --arg value "$SECRET_VALUE" '{name: $name, value: $value}')
    
    # Send POST request to create the secret
    response=$(curl -s -X POST "${BASE_URL}/secrets" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# delete_secret()
# -----------------------------------------------------------------------------
# Deletes an existing secret from the Devin account.
#
# Required inputs:
#   - SECRET_ID: The unique identifier of the secret to delete
#
# Outputs:
#   - response: The API response confirming deletion
# -----------------------------------------------------------------------------
function delete_secret() {
    # Validate required parameter
    if [ -z "$SECRET_ID" ]; then
        echo "Error: secret-id is required for delete-secret action"
        exit 1
    fi
    
    # Send DELETE request to remove the secret
    response=$(curl -s -X DELETE "${BASE_URL}/secrets/${SECRET_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# =============================================================================
# KNOWLEDGE MANAGEMENT FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# list_knowledge()
# -----------------------------------------------------------------------------
# Lists all knowledge entries in the Devin account.
#
# Knowledge entries provide persistent context and information that
# Devin can reference across sessions.
#
# Outputs:
#   - response: JSON array of knowledge entry objects
# -----------------------------------------------------------------------------
function list_knowledge() {
    # Send GET request to list all knowledge entries
    response=$(curl -s -X GET "${BASE_URL}/knowledge" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# create_knowledge()
# -----------------------------------------------------------------------------
# Creates a new knowledge entry in the Devin account.
#
# Knowledge entries can contain documentation, guidelines, or any
# information you want Devin to have access to during sessions.
#
# Required inputs:
#   - KNOWLEDGE_NAME: A descriptive name for the knowledge entry
#   - KNOWLEDGE_CONTENT: The actual content/information
#
# Outputs:
#   - response: The API response with the created entry's metadata
# -----------------------------------------------------------------------------
function create_knowledge() {
    # Validate required parameters
    if [ -z "$KNOWLEDGE_NAME" ] || [ -z "$KNOWLEDGE_CONTENT" ]; then
        echo "Error: knowledge-name and knowledge-content are required for create-knowledge action"
        exit 1
    fi
    
    # Build JSON payload with knowledge name and content
    local payload=$(jq -n --arg name "$KNOWLEDGE_NAME" --arg content "$KNOWLEDGE_CONTENT" '{name: $name, content: $content}')
    
    # Send POST request to create the knowledge entry
    response=$(curl -s -X POST "${BASE_URL}/knowledge" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# update_knowledge()
# -----------------------------------------------------------------------------
# Updates an existing knowledge entry.
#
# You can update the name, content, or both.
#
# Required inputs:
#   - KNOWLEDGE_ID: The unique identifier of the knowledge entry
#
# Optional inputs:
#   - KNOWLEDGE_NAME: New name for the entry
#   - KNOWLEDGE_CONTENT: New content for the entry
#
# Outputs:
#   - response: The API response confirming the update
# -----------------------------------------------------------------------------
function update_knowledge() {
    # Validate required parameter
    if [ -z "$KNOWLEDGE_ID" ]; then
        echo "Error: knowledge-id is required for update-knowledge action"
        exit 1
    fi
    
    # Build payload dynamically based on provided parameters
    local payload_obj='{}'
    if [ -n "$KNOWLEDGE_NAME" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg name "$KNOWLEDGE_NAME" '. + {name: $name}')
    fi
    if [ -n "$KNOWLEDGE_CONTENT" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg content "$KNOWLEDGE_CONTENT" '. + {content: $content}')
    fi
    local payload="$payload_obj"
    
    # Send PUT request to update the knowledge entry
    response=$(curl -s -X PUT "${BASE_URL}/knowledge/${KNOWLEDGE_ID}" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# delete_knowledge()
# -----------------------------------------------------------------------------
# Deletes an existing knowledge entry.
#
# Required inputs:
#   - KNOWLEDGE_ID: The unique identifier of the knowledge entry to delete
#
# Outputs:
#   - response: The API response confirming deletion
# -----------------------------------------------------------------------------
function delete_knowledge() {
    # Validate required parameter
    if [ -z "$KNOWLEDGE_ID" ]; then
        echo "Error: knowledge-id is required for delete-knowledge action"
        exit 1
    fi
    
    # Send DELETE request to remove the knowledge entry
    response=$(curl -s -X DELETE "${BASE_URL}/knowledge/${KNOWLEDGE_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# =============================================================================
# PLAYBOOKS MANAGEMENT FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# list_playbooks()
# -----------------------------------------------------------------------------
# Lists all playbooks in the Devin account.
#
# Playbooks are reusable sets of instructions that define how Devin
# should approach specific types of tasks.
#
# Outputs:
#   - response: JSON array of playbook objects
# -----------------------------------------------------------------------------
function list_playbooks() {
    # Send GET request to list all playbooks
    response=$(curl -s -X GET "${BASE_URL}/playbooks" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# create_playbook()
# -----------------------------------------------------------------------------
# Creates a new playbook in the Devin account.
#
# Playbooks define workflows and instructions that Devin can follow
# for specific types of tasks.
#
# Required inputs:
#   - PLAYBOOK_NAME: A descriptive name for the playbook
#   - PLAYBOOK_CONTENT: The playbook instructions/content
#
# Outputs:
#   - response: The API response with the created playbook's metadata
# -----------------------------------------------------------------------------
function create_playbook() {
    # Validate required parameters
    if [ -z "$PLAYBOOK_NAME" ] || [ -z "$PLAYBOOK_CONTENT" ]; then
        echo "Error: playbook-name and playbook-content are required for create-playbook action"
        exit 1
    fi
    
    # Build JSON payload with playbook name and content
    local payload=$(jq -n --arg name "$PLAYBOOK_NAME" --arg content "$PLAYBOOK_CONTENT" '{name: $name, content: $content}')
    
    # Send POST request to create the playbook
    response=$(curl -s -X POST "${BASE_URL}/playbooks" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# get_playbook()
# -----------------------------------------------------------------------------
# Retrieves details about a specific playbook.
#
# Required inputs:
#   - PLAYBOOK_ID: The unique identifier of the playbook
#
# Outputs:
#   - response: The full JSON response containing playbook details
# -----------------------------------------------------------------------------
function get_playbook() {
    # Validate required parameter
    if [ -z "$PLAYBOOK_ID" ]; then
        echo "Error: playbook-id is required for get-playbook action"
        exit 1
    fi
    
    # Send GET request to retrieve playbook details
    response=$(curl -s -X GET "${BASE_URL}/playbooks/${PLAYBOOK_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# update_playbook()
# -----------------------------------------------------------------------------
# Updates an existing playbook.
#
# You can update the name, content, or both.
#
# Required inputs:
#   - PLAYBOOK_ID: The unique identifier of the playbook
#
# Optional inputs:
#   - PLAYBOOK_NAME: New name for the playbook
#   - PLAYBOOK_CONTENT: New content for the playbook
#
# Outputs:
#   - response: The API response confirming the update
# -----------------------------------------------------------------------------
function update_playbook() {
    # Validate required parameter
    if [ -z "$PLAYBOOK_ID" ]; then
        echo "Error: playbook-id is required for update-playbook action"
        exit 1
    fi
    
    # Build payload dynamically based on provided parameters
    local payload_obj='{}'
    if [ -n "$PLAYBOOK_NAME" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg name "$PLAYBOOK_NAME" '. + {name: $name}')
    fi
    if [ -n "$PLAYBOOK_CONTENT" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg content "$PLAYBOOK_CONTENT" '. + {content: $content}')
    fi
    local payload="$payload_obj"
    
    # Send PUT request to update the playbook
    response=$(curl -s -X PUT "${BASE_URL}/playbooks/${PLAYBOOK_ID}" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# -----------------------------------------------------------------------------
# delete_playbook()
# -----------------------------------------------------------------------------
# Deletes an existing playbook.
#
# Required inputs:
#   - PLAYBOOK_ID: The unique identifier of the playbook to delete
#
# Outputs:
#   - response: The API response confirming deletion
# -----------------------------------------------------------------------------
function delete_playbook() {
    # Validate required parameter
    if [ -z "$PLAYBOOK_ID" ]; then
        echo "Error: playbook-id is required for delete-playbook action"
        exit 1
    fi
    
    # Send DELETE request to remove the playbook
    response=$(curl -s -X DELETE "${BASE_URL}/playbooks/${PLAYBOOK_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
# Route to the appropriate function based on the ACTION parameter
# Uses a case statement for efficient action dispatch

case "$ACTION" in
    # -------------------------------------------------------------------------
    # Session Management Actions
    # -------------------------------------------------------------------------
    create-session)
        create_session
        ;;
    send-message)
        send_message
        ;;
    get-session)
        get_session
        ;;
    list-sessions)
        list_sessions
        ;;
    upload-files)
        upload_files
        ;;
    update-tags)
        update_tags
        ;;
    
    # -------------------------------------------------------------------------
    # Secrets Management Actions
    # -------------------------------------------------------------------------
    list-secrets)
        list_secrets
        ;;
    create-secret)
        create_secret
        ;;
    delete-secret)
        delete_secret
        ;;
    
    # -------------------------------------------------------------------------
    # Knowledge Management Actions
    # -------------------------------------------------------------------------
    list-knowledge)
        list_knowledge
        ;;
    create-knowledge)
        create_knowledge
        ;;
    update-knowledge)
        update_knowledge
        ;;
    delete-knowledge)
        delete_knowledge
        ;;
    
    # -------------------------------------------------------------------------
    # Playbooks Management Actions
    # -------------------------------------------------------------------------
    list-playbooks)
        list_playbooks
        ;;
    create-playbook)
        create_playbook
        ;;
    get-playbook)
        get_playbook
        ;;
    update-playbook)
        update_playbook
        ;;
    delete-playbook)
        delete_playbook
        ;;
    
    # -------------------------------------------------------------------------
    # Handle unknown actions with helpful error message
    # -------------------------------------------------------------------------
    *)
        echo "Error: Unknown action '${ACTION}'"
        echo "Valid actions: create-session, send-message, get-session, list-sessions, upload-files, update-tags, list-secrets, create-secret, delete-secret, list-knowledge, create-knowledge, update-knowledge, delete-knowledge, list-playbooks, create-playbook, get-playbook, update-playbook, delete-playbook"
        exit 1
        ;;
esac
