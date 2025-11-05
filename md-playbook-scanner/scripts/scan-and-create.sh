#!/bin/bash

set -e

DIRECTORY="$1"
API_KEY="$2"

BASE_URL="https://api.devin.ai/v1"

if [ -z "$DIRECTORY" ]; then
    echo "Error: directory is required"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "Error: api-key is required"
    exit 1
fi

if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist"
    exit 1
fi

echo "Scanning directory: $DIRECTORY"

playbooks_created=0
playbooks_failed=0
declare -a created_playbook_ids
declare -a failed_files

while IFS= read -r -d '' file; do
    echo "Processing: $file"
    
    filename=$(basename "$file" .md)
    
    if [ -z "$filename" ]; then
        echo "  Skipping: empty filename"
        playbooks_failed=$((playbooks_failed + 1))
        failed_files+=("$file")
        continue
    fi
    
    content=$(cat "$file")
    
    if [ -z "$content" ]; then
        echo "  Warning: empty content in $file"
    fi
    
    payload=$(jq -n \
        --arg title "$filename" \
        --arg body "$content" \
        '{title: $title, body: $body}')
    
    response=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/playbooks" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        playbook_id=$(echo "$response_body" | jq -r '.playbook_id // empty')
        if [ -n "$playbook_id" ]; then
            echo "  ✓ Created playbook: $filename (ID: $playbook_id)"
            playbooks_created=$((playbooks_created + 1))
            created_playbook_ids+=("$playbook_id")
        else
            echo "  ✗ Failed to extract playbook_id from response"
            playbooks_failed=$((playbooks_failed + 1))
            failed_files+=("$file")
        fi
    else
        echo "  ✗ Failed to create playbook (HTTP $http_code): $response_body"
        playbooks_failed=$((playbooks_failed + 1))
        failed_files+=("$file")
    fi
    
done < <(find "$DIRECTORY" -type f -name "*.md" -print0)

echo ""
echo "=========================================="
echo "Summary:"
echo "  Total .md files found: $((playbooks_created + playbooks_failed))"
echo "  Playbooks created: $playbooks_created"
echo "  Failed: $playbooks_failed"
echo "=========================================="

echo "playbooks-created=$playbooks_created" >> $GITHUB_OUTPUT
echo "playbooks-failed=$playbooks_failed" >> $GITHUB_OUTPUT

if [ ${#created_playbook_ids[@]} -gt 0 ]; then
    playbook_ids_json=$(printf '%s\n' "${created_playbook_ids[@]}" | jq -R . | jq -s .)
    echo "playbook-ids<<EOF" >> $GITHUB_OUTPUT
    echo "$playbook_ids_json" >> $GITHUB_OUTPUT
    echo "EOF" >> $GITHUB_OUTPUT
fi

if [ ${#failed_files[@]} -gt 0 ]; then
    echo ""
    echo "Failed files:"
    printf '  - %s\n' "${failed_files[@]}"
fi

if [ $playbooks_failed -gt 0 ]; then
    exit 1
fi
