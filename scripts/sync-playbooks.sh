#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local response_file="${TEMP_DIR}/api_response.json"
    
    local url="${API_BASE_URL}${endpoint}"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN: Would call $method $url"
        if [ -n "$data" ]; then
            log_info "Request data: $data"
        fi
        echo '{"status":"dry-run","message":"Dry run mode - no actual API call made"}'
        return 0
    fi
    
    local http_code
    if [ -n "$data" ]; then
        http_code=$(curl -s -w "%{http_code}" -o "$response_file" \
            -X "$method" \
            -H "Authorization: Bearer ${DEVIN_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url")
    else
        http_code=$(curl -s -w "%{http_code}" -o "$response_file" \
            -X "$method" \
            -H "Authorization: Bearer ${DEVIN_API_KEY}" \
            "$url")
    fi
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        cat "$response_file"
        return 0
    else
        log_error "API call failed with status $http_code"
        cat "$response_file" >&2
        return 1
    fi
}

create_playbook() {
    local file_path="$1"
    local title
    local body
    
    title=$(basename "$file_path" .md)
    body=$(cat "$file_path")
    
    log_info "Creating playbook: $title"
    
    local json_data
    if [ -n "$PLAYBOOK_MACRO" ]; then
        json_data=$(jq -n \
            --arg title "$title" \
            --arg body "$body" \
            --arg macro "$PLAYBOOK_MACRO" \
            '{title: $title, body: $body, macro: $macro}')
    else
        json_data=$(jq -n \
            --arg title "$title" \
            --arg body "$body" \
            '{title: $title, body: $body}')
    fi
    
    local response
    if response=$(api_call "POST" "/v1/playbooks" "$json_data"); then
        local playbook_id
        playbook_id=$(echo "$response" | jq -r '.playbook_id // .id // empty')
        
        if [ -n "$playbook_id" ]; then
            log_success "Created playbook '$title' with ID: $playbook_id"
            echo "$playbook_id" >> "${TEMP_DIR}/playbook_ids.txt"
        else
            log_warning "Playbook created but ID not found in response"
        fi
        return 0
    else
        log_error "Failed to create playbook: $title"
        return 1
    fi
}

list_playbooks() {
    log_info "Fetching all playbooks..."
    
    local response
    if response=$(api_call "GET" "/v1/playbooks" ""); then
        echo "$response" | jq '.'
        
        local count
        count=$(echo "$response" | jq 'length // 0')
        log_success "Found $count playbook(s)"
        
        echo "playbooks-count=$count" >> "$GITHUB_OUTPUT"
        echo "operation-result<<EOF" >> "$GITHUB_OUTPUT"
        echo "$response" >> "$GITHUB_OUTPUT"
        echo "EOF" >> "$GITHUB_OUTPUT"
        return 0
    else
        log_error "Failed to list playbooks"
        return 1
    fi
}

get_playbook() {
    local playbook_id="$1"
    log_info "Fetching playbook: $playbook_id"
    
    local response
    if response=$(api_call "GET" "/v1/playbooks/${playbook_id}" ""); then
        echo "$response" | jq '.'
        log_success "Retrieved playbook: $playbook_id"
        
        echo "operation-result<<EOF" >> "$GITHUB_OUTPUT"
        echo "$response" >> "$GITHUB_OUTPUT"
        echo "EOF" >> "$GITHUB_OUTPUT"
        return 0
    else
        log_error "Failed to get playbook: $playbook_id"
        return 1
    fi
}

update_playbook() {
    local playbook_id="$1"
    log_info "Updating playbook: $playbook_id"
    
    local title="$PLAYBOOK_TITLE"
    local body="$PLAYBOOK_BODY"
    
    if [ -z "$title" ] && [ -z "$body" ]; then
        log_error "Either title or body must be provided for update"
        return 1
    fi
    
    if [ -z "$title" ] || [ -z "$body" ]; then
        local current
        if current=$(api_call "GET" "/v1/playbooks/${playbook_id}" ""); then
            if [ -z "$title" ]; then
                title=$(echo "$current" | jq -r '.title')
            fi
            if [ -z "$body" ]; then
                body=$(echo "$current" | jq -r '.body')
            fi
        else
            log_error "Failed to fetch current playbook for update"
            return 1
        fi
    fi
    
    local json_data
    if [ -n "$PLAYBOOK_MACRO" ]; then
        json_data=$(jq -n \
            --arg title "$title" \
            --arg body "$body" \
            --arg macro "$PLAYBOOK_MACRO" \
            '{title: $title, body: $body, macro: $macro}')
    else
        json_data=$(jq -n \
            --arg title "$title" \
            --arg body "$body" \
            '{title: $title, body: $body}')
    fi
    
    local response
    if response=$(api_call "PUT" "/v1/playbooks/${playbook_id}" "$json_data"); then
        log_success "Updated playbook: $playbook_id"
        
        echo "operation-result<<EOF" >> "$GITHUB_OUTPUT"
        echo "$response" >> "$GITHUB_OUTPUT"
        echo "EOF" >> "$GITHUB_OUTPUT"
        return 0
    else
        log_error "Failed to update playbook: $playbook_id"
        return 1
    fi
}

delete_playbook() {
    local playbook_id="$1"
    log_info "Deleting playbook: $playbook_id"
    
    local response
    if response=$(api_call "DELETE" "/v1/playbooks/${playbook_id}" ""); then
        log_success "Deleted playbook: $playbook_id"
        
        echo "operation-result<<EOF" >> "$GITHUB_OUTPUT"
        echo "$response" >> "$GITHUB_OUTPUT"
        echo "EOF" >> "$GITHUB_OUTPUT"
        return 0
    else
        log_error "Failed to delete playbook: $playbook_id"
        return 1
    fi
}

sync_markdown_files() {
    log_info "Scanning directory: $DIRECTORY"
    
    local find_cmd="find \"$DIRECTORY\" -type f -name '*.md'"
    if [ "$RECURSIVE" != "true" ]; then
        find_cmd="find \"$DIRECTORY\" -maxdepth 1 -type f -name '*.md'"
    fi
    
    local md_files
    md_files=$(eval "$find_cmd" | sort)
    
    if [ -z "$md_files" ]; then
        log_warning "No .md files found in $DIRECTORY"
        echo "playbooks-count=0" >> "$GITHUB_OUTPUT"
        echo "playbook-ids=" >> "$GITHUB_OUTPUT"
        return 0
    fi
    
    local total_files
    total_files=$(echo "$md_files" | wc -l)
    log_info "Found $total_files markdown file(s)"
    
    echo "::group::Creating playbooks"
    
    local success_count=0
    local failed_count=0
    
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            if create_playbook "$file"; then
                ((success_count++))
            else
                ((failed_count++))
            fi
        fi
    done <<< "$md_files"
    
    echo "::endgroup::"
    
    log_success "Successfully created $success_count playbook(s)"
    if [ $failed_count -gt 0 ]; then
        log_warning "Failed to create $failed_count playbook(s)"
    fi
    
    if [ -f "${TEMP_DIR}/playbook_ids.txt" ]; then
        local ids
        ids=$(cat "${TEMP_DIR}/playbook_ids.txt" | tr '\n' ',' | sed 's/,$//')
        echo "playbook-ids=$ids" >> "$GITHUB_OUTPUT"
    else
        echo "playbook-ids=" >> "$GITHUB_OUTPUT"
    fi
    
    echo "playbooks-count=$success_count" >> "$GITHUB_OUTPUT"
}

main() {
    echo "::group::Devin Playbook Sync - ${OPERATION}"
    log_info "Starting operation: $OPERATION"
    log_info "API Base URL: $API_BASE_URL"
    
    case "$OPERATION" in
        sync)
            sync_markdown_files
            ;;
        list)
            list_playbooks
            ;;
        get)
            get_playbook "$PLAYBOOK_ID"
            ;;
        update)
            update_playbook "$PLAYBOOK_ID"
            ;;
        delete)
            delete_playbook "$PLAYBOOK_ID"
            ;;
        *)
            log_error "Unknown operation: $OPERATION"
            exit 1
            ;;
    esac
    
    echo "::endgroup::"
    log_success "Operation completed successfully"
}

main
