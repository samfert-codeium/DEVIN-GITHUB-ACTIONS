#!/bin/bash

set -e

ACTION="$1"
API_KEY="$2"
PROMPT="$3"
SESSION_ID="$4"
MESSAGE="$5"
SNAPSHOT_ID="$6"
UNLISTED="$7"
IDEMPOTENT="$8"
MAX_ACU_LIMIT="$9"
SECRET_IDS="${10}"
KNOWLEDGE_IDS="${11}"
TAGS="${12}"
TITLE="${13}"
FILE_PATH="${14}"
SECRET_ID="${15}"
SECRET_NAME="${16}"
SECRET_VALUE="${17}"
KNOWLEDGE_ID="${18}"
KNOWLEDGE_NAME="${19}"
KNOWLEDGE_CONTENT="${20}"
PLAYBOOK_ID="${21}"
PLAYBOOK_NAME="${22}"
PLAYBOOK_CONTENT="${23}"
ATTACHMENT_UUID="${24}"
ATTACHMENT_NAME="${25}"

BASE_URL="https://api.devin.ai/v1"

function create_session() {
    local payload_obj='{}'
    
    payload_obj=$(echo "$payload_obj" | jq --arg prompt "$PROMPT" '. + {prompt: $prompt}')
    
    if [ -n "$SNAPSHOT_ID" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg snapshot_id "$SNAPSHOT_ID" '. + {snapshot_id: $snapshot_id}')
    fi
    
    if [ "$UNLISTED" = "true" ]; then
        payload_obj=$(echo "$payload_obj" | jq '. + {unlisted: true}')
    fi
    
    if [ "$IDEMPOTENT" = "true" ]; then
        payload_obj=$(echo "$payload_obj" | jq '. + {idempotent: true}')
    fi
    
    if [ -n "$MAX_ACU_LIMIT" ]; then
        payload_obj=$(echo "$payload_obj" | jq --argjson max_acu_limit "$MAX_ACU_LIMIT" '. + {max_acu_limit: $max_acu_limit}')
    fi
    
    if [ -n "$SECRET_IDS" ]; then
        IFS=',' read -ra SECRET_ARRAY <<< "$SECRET_IDS"
        secret_ids_json=$(printf '%s\n' "${SECRET_ARRAY[@]}" | jq -R . | jq -s .)
        payload_obj=$(echo "$payload_obj" | jq --argjson secret_ids "$secret_ids_json" '. + {secret_ids: $secret_ids}')
    fi
    
    if [ -n "$KNOWLEDGE_IDS" ]; then
        IFS=',' read -ra KNOWLEDGE_ARRAY <<< "$KNOWLEDGE_IDS"
        knowledge_ids_json=$(printf '%s\n' "${KNOWLEDGE_ARRAY[@]}" | jq -R . | jq -s .)
        payload_obj=$(echo "$payload_obj" | jq --argjson knowledge_ids "$knowledge_ids_json" '. + {knowledge_ids: $knowledge_ids}')
    fi
    
    if [ -n "$TAGS" ]; then
        IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
        tags_json=$(printf '%s\n' "${TAG_ARRAY[@]}" | jq -R . | jq -s .)
        payload_obj=$(echo "$payload_obj" | jq --argjson tags "$tags_json" '. + {tags: $tags}')
    fi
    
    if [ -n "$TITLE" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg title "$TITLE" '. + {title: $title}')
    fi
    
    local payload="$payload_obj"
    
    response=$(curl -s -X POST "${BASE_URL}/sessions" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "${payload}")
    
    echo "${response}"
    
    session_id=$(echo "${response}" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
    session_url=$(echo "${response}" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    is_new=$(echo "${response}" | grep -o '"is_new_session":[^,}]*' | cut -d':' -f2)
    
    echo "session-id=${session_id}" >> $GITHUB_OUTPUT
    echo "session-url=${session_url}" >> $GITHUB_OUTPUT
    echo "is-new-session=${is_new}" >> $GITHUB_OUTPUT
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function send_message() {
    if [ -z "$SESSION_ID" ] || [ -z "$MESSAGE" ]; then
        echo "Error: session-id and message are required for send-message action"
        exit 1
    fi
    
    local payload=$(jq -n --arg message "$MESSAGE" '{message: $message}')
    
    response=$(curl -s -X POST "${BASE_URL}/sessions/${SESSION_ID}/message" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function get_session() {
    if [ -z "$SESSION_ID" ]; then
        echo "Error: session-id is required for get-session action"
        exit 1
    fi
    
    response=$(curl -s -X GET "${BASE_URL}/sessions/${SESSION_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function list_sessions() {
    response=$(curl -s -X GET "${BASE_URL}/sessions" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function upload_files() {
    if [ -z "$SESSION_ID" ] || [ -z "$FILE_PATH" ]; then
        echo "Error: session-id and file-path are required for upload-files action"
        exit 1
    fi
    
    if [ ! -f "$FILE_PATH" ]; then
        echo "Error: File not found: ${FILE_PATH}"
        exit 1
    fi
    
    response=$(curl -s -X POST "${BASE_URL}/sessions/${SESSION_ID}/attachments" \
        -H "Authorization: Bearer ${API_KEY}" \
        -F "file=@${FILE_PATH}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function update_tags() {
    if [ -z "$SESSION_ID" ] || [ -z "$TAGS" ]; then
        echo "Error: session-id and tags are required for update-tags action"
        exit 1
    fi
    
    IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
    tags_json=$(printf '%s\n' "${TAG_ARRAY[@]}" | jq -R . | jq -s .)
    local payload=$(jq -n --argjson tags "$tags_json" '{tags: $tags}')
    
    response=$(curl -s -X PUT "${BASE_URL}/sessions/${SESSION_ID}/tags" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function list_secrets() {
    response=$(curl -s -X GET "${BASE_URL}/secrets" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function create_secret() {
    if [ -z "$SECRET_NAME" ] || [ -z "$SECRET_VALUE" ]; then
        echo "Error: secret-name and secret-value are required for create-secret action"
        exit 1
    fi
    
    local payload=$(jq -n --arg name "$SECRET_NAME" --arg value "$SECRET_VALUE" '{name: $name, value: $value}')
    
    response=$(curl -s -X POST "${BASE_URL}/secrets" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function delete_secret() {
    if [ -z "$SECRET_ID" ]; then
        echo "Error: secret-id is required for delete-secret action"
        exit 1
    fi
    
    response=$(curl -s -X DELETE "${BASE_URL}/secrets/${SECRET_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function list_knowledge() {
    response=$(curl -s -X GET "${BASE_URL}/knowledge" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function create_knowledge() {
    if [ -z "$KNOWLEDGE_NAME" ] || [ -z "$KNOWLEDGE_CONTENT" ]; then
        echo "Error: knowledge-name and knowledge-content are required for create-knowledge action"
        exit 1
    fi
    
    local payload=$(jq -n --arg name "$KNOWLEDGE_NAME" --arg content "$KNOWLEDGE_CONTENT" '{name: $name, content: $content}')
    
    response=$(curl -s -X POST "${BASE_URL}/knowledge" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function update_knowledge() {
    if [ -z "$KNOWLEDGE_ID" ]; then
        echo "Error: knowledge-id is required for update-knowledge action"
        exit 1
    fi
    
    local payload_obj='{}'
    if [ -n "$KNOWLEDGE_NAME" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg name "$KNOWLEDGE_NAME" '. + {name: $name}')
    fi
    if [ -n "$KNOWLEDGE_CONTENT" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg content "$KNOWLEDGE_CONTENT" '. + {content: $content}')
    fi
    local payload="$payload_obj"
    
    response=$(curl -s -X PUT "${BASE_URL}/knowledge/${KNOWLEDGE_ID}" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function delete_knowledge() {
    if [ -z "$KNOWLEDGE_ID" ]; then
        echo "Error: knowledge-id is required for delete-knowledge action"
        exit 1
    fi
    
    response=$(curl -s -X DELETE "${BASE_URL}/knowledge/${KNOWLEDGE_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function list_playbooks() {
    response=$(curl -s -X GET "${BASE_URL}/playbooks" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function create_playbook() {
    if [ -z "$PLAYBOOK_NAME" ] || [ -z "$PLAYBOOK_CONTENT" ]; then
        echo "Error: playbook-name and playbook-content are required for create-playbook action"
        exit 1
    fi
    
    local payload=$(jq -n --arg name "$PLAYBOOK_NAME" --arg content "$PLAYBOOK_CONTENT" '{name: $name, content: $content}')
    
    response=$(curl -s -X POST "${BASE_URL}/playbooks" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function get_playbook() {
    if [ -z "$PLAYBOOK_ID" ]; then
        echo "Error: playbook-id is required for get-playbook action"
        exit 1
    fi
    
    response=$(curl -s -X GET "${BASE_URL}/playbooks/${PLAYBOOK_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function update_playbook() {
    if [ -z "$PLAYBOOK_ID" ]; then
        echo "Error: playbook-id is required for update-playbook action"
        exit 1
    fi
    
    local payload_obj='{}'
    if [ -n "$PLAYBOOK_NAME" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg name "$PLAYBOOK_NAME" '. + {name: $name}')
    fi
    if [ -n "$PLAYBOOK_CONTENT" ]; then
        payload_obj=$(echo "$payload_obj" | jq --arg content "$PLAYBOOK_CONTENT" '. + {content: $content}')
    fi
    local payload="$payload_obj"
    
    response=$(curl -s -X PUT "${BASE_URL}/playbooks/${PLAYBOOK_ID}" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function delete_playbook() {
    if [ -z "$PLAYBOOK_ID" ]; then
        echo "Error: playbook-id is required for delete-playbook action"
        exit 1
    fi
    
    response=$(curl -s -X DELETE "${BASE_URL}/playbooks/${PLAYBOOK_ID}" \
        -H "Authorization: Bearer ${API_KEY}")
    
    echo "${response}"
    echo "response=${response}" >> $GITHUB_OUTPUT
}

function download_attachment_files() {
    if [ -z "$ATTACHMENT_UUID" ] || [ -z "$ATTACHMENT_NAME" ]; then
        echo "Error: attachment-uuid and attachment-name are required for download-attachment-files action"
        exit 1
    fi
    
    response=$(curl -s -L -X GET "${BASE_URL}/attachments/${ATTACHMENT_UUID}/${ATTACHMENT_NAME}" \
        -H "Authorization: Bearer ${API_KEY}" \
        -w "\n%{http_code}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "307" ]; then
        echo "${body}"
        echo "response=${body}" >> $GITHUB_OUTPUT
        echo "http-code=${http_code}" >> $GITHUB_OUTPUT
    else
        echo "Error: Failed to download attachment. HTTP code: ${http_code}"
        echo "${body}"
        echo "response=${body}" >> $GITHUB_OUTPUT
        echo "http-code=${http_code}" >> $GITHUB_OUTPUT
        exit 1
    fi
}

case "$ACTION" in
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
    list-secrets)
        list_secrets
        ;;
    create-secret)
        create_secret
        ;;
    delete-secret)
        delete_secret
        ;;
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
    download-attachment-files)
        download_attachment_files
        ;;
    *)
        echo "Error: Unknown action '${ACTION}'"
        echo "Valid actions: create-session, send-message, get-session, list-sessions, upload-files, update-tags, list-secrets, create-secret, delete-secret, list-knowledge, create-knowledge, update-knowledge, delete-knowledge, list-playbooks, create-playbook, get-playbook, update-playbook, delete-playbook, download-attachment-files"
        exit 1
        ;;
esac
