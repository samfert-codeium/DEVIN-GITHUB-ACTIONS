# Devin API GitHub Action

A comprehensive GitHub Action for interacting with the Devin API to create and manage Devin sessions programmatically from your GitHub workflows.

## Features

This action supports all Devin API functionalities:

- **Session Management**: Create sessions, send messages, get session details, list sessions, upload files, download attachment files, update tags
- **Secrets Management**: List, create, and delete secrets
- **Knowledge Management**: List, create, update, and delete knowledge
- **Playbooks Management**: List, create, get, update, and delete playbooks

## Prerequisites

Before using this action, you need:

1. A Devin API key from your [Devin settings page](https://app.devin.ai/settings)
2. Store the API key as a GitHub secret (recommended name: `DEVIN_API_KEY`)

## Usage

### Basic Examples

#### Create a Devin Session

```yaml
- name: Create Devin Session
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: create-session
  with:
    action: 'create-session'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    prompt: 'Fix the failing unit tests in the user service'
    title: 'Fix User Service Tests'
    tags: 'bug-fix,unit-tests'

- name: Print Session Info
  run: |
    echo "Session ID: ${{ steps.create-session.outputs.session-id }}"
    echo "Session URL: ${{ steps.create-session.outputs.session-url }}"
```

#### Send a Message to Existing Session

```yaml
- name: Send Message to Devin
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'send-message'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    session-id: ${{ steps.create-session.outputs.session-id }}
    message: 'Please also update the integration tests'
```

#### Get Session Status

```yaml
- name: Check Session Status
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: check-status
  with:
    action: 'get-session'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    session-id: ${{ steps.create-session.outputs.session-id }}

- name: Print Status
  run: echo "Response: ${{ steps.check-status.outputs.response }}"
```

#### List All Sessions

```yaml
- name: List Sessions
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: list-sessions
  with:
    action: 'list-sessions'
    api-key: ${{ secrets.DEVIN_API_KEY }}

- name: Print Sessions
  run: echo "Sessions: ${{ steps.list-sessions.outputs.response }}"
```

### Advanced Examples

#### Create Session with All Options

```yaml
- name: Create Advanced Session
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: advanced-session
  with:
    action: 'create-session'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    prompt: 'Implement new authentication feature'
    title: 'Auth Feature Implementation'
    snapshot-id: 'snap_123456'
    unlisted: 'true'
    idempotent: 'true'
    max-acu-limit: '1000'
    secret-ids: 'secret1,secret2,secret3'
    knowledge-ids: 'knowledge1,knowledge2'
    tags: 'feature,authentication,high-priority'
```

#### Upload Files to Session

```yaml
- name: Upload Test Results
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'upload-files'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    session-id: ${{ steps.create-session.outputs.session-id }}
    file-path: './test-results.xml'
```

#### Update Session Tags

```yaml
- name: Update Session Tags
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'update-tags'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    session-id: ${{ steps.create-session.outputs.session-id }}
    tags: 'completed,reviewed,deployed'
```

#### Download Attachment Files

```yaml
- name: Download Attachment from Session
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: download-attachment
  with:
    action: 'download-attachment-files'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    attachment-uuid: 'uuid_123456'
    attachment-name: 'report.pdf'

- name: Save Attachment
  run: |
    echo "${{ steps.download-attachment.outputs.response }}" > report.pdf
```

### Secrets Management

#### List Secrets

```yaml
- name: List Available Secrets
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: list-secrets
  with:
    action: 'list-secrets'
    api-key: ${{ secrets.DEVIN_API_KEY }}
```

#### Create Secret

```yaml
- name: Create Secret
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'create-secret'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    secret-name: 'DATABASE_PASSWORD'
    secret-value: ${{ secrets.DB_PASSWORD }}
```

#### Delete Secret

```yaml
- name: Delete Secret
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'delete-secret'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    secret-id: 'secret_id_123'
```

### Knowledge Management

#### Create Knowledge

```yaml
- name: Create Knowledge Entry
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'create-knowledge'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    knowledge-name: 'API Documentation'
    knowledge-content: 'Our API endpoints are documented at /docs/api'
```

#### Update Knowledge

```yaml
- name: Update Knowledge
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'update-knowledge'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    knowledge-id: 'knowledge_123'
    knowledge-name: 'Updated API Documentation'
    knowledge-content: 'API endpoints moved to /api/v2/docs'
```

### Playbooks Management

#### Create Playbook

```yaml
- name: Create Playbook
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  with:
    action: 'create-playbook'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    playbook-name: 'Bug Fix Workflow'
    playbook-content: 'Step 1: Identify issue, Step 2: Write test, Step 3: Fix'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `action` | The API action to perform | Yes | - |
| `api-key` | Devin API key for authentication | Yes | - |
| `prompt` | Task description for Devin | For `create-session` | - |
| `session-id` | Session ID | For session operations | - |
| `message` | Message to send to Devin | For `send-message` | - |
| `snapshot-id` | Machine snapshot ID | No | - |
| `unlisted` | Make session unlisted | No | `false` |
| `idempotent` | Enable idempotent creation | No | `false` |
| `max-acu-limit` | Maximum ACU limit | No | - |
| `secret-ids` | Comma-separated secret IDs | No | - |
| `knowledge-ids` | Comma-separated knowledge IDs | No | - |
| `tags` | Comma-separated tags | No | - |
| `title` | Custom session title | No | - |
| `file-path` | File path for upload | For `upload-files` | - |
| `secret-id` | Secret ID | For secret operations | - |
| `secret-name` | Secret name | For `create-secret` | - |
| `secret-value` | Secret value | For `create-secret` | - |
| `knowledge-id` | Knowledge ID | For knowledge operations | - |
| `knowledge-name` | Knowledge name | For knowledge operations | - |
| `knowledge-content` | Knowledge content | For knowledge operations | - |
| `playbook-id` | Playbook ID | For playbook operations | - |
| `playbook-name` | Playbook name | For playbook operations | - |
| `playbook-content` | Playbook content | For playbook operations | - |
| `attachment-uuid` | Attachment UUID | For `download-attachment-files` | - |
| `attachment-name` | Attachment filename | For `download-attachment-files` | - |

## Outputs

| Output | Description |
|--------|-------------|
| `session-id` | The session ID (for create-session) |
| `session-url` | The session URL (for create-session) |
| `is-new-session` | Whether a new session was created (for idempotent create-session) |
| `response` | The full API response |

## Available Actions

- `create-session` - Create a new Devin session
- `send-message` - Send a message to an existing session
- `get-session` - Get details about a session
- `list-sessions` - List all sessions
- `upload-files` - Upload files to a session
- `download-attachment-files` - Download attachment files from a session
- `update-tags` - Update session tags
- `list-secrets` - List all secrets
- `create-secret` - Create a new secret
- `delete-secret` - Delete a secret
- `list-knowledge` - List all knowledge entries
- `create-knowledge` - Create a new knowledge entry
- `update-knowledge` - Update a knowledge entry
- `delete-knowledge` - Delete a knowledge entry
- `list-playbooks` - List all playbooks
- `create-playbook` - Create a new playbook
- `get-playbook` - Get a specific playbook
- `update-playbook` - Update a playbook
- `delete-playbook` - Delete a playbook

## Complete Workflow Example

Here's a complete example workflow that demonstrates multiple features:

```yaml
name: Automated Code Review with Devin

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  devin-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Create Devin Session for PR Review
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
        id: create-session
        with:
          action: 'create-session'
          api-key: ${{ secrets.DEVIN_API_KEY }}
          prompt: |
            Review this pull request and check for:
            1. Code quality issues
            2. Security vulnerabilities
            3. Test coverage
            PR: ${{ github.event.pull_request.html_url }}
          title: 'PR Review - ${{ github.event.pull_request.title }}'
          tags: 'pr-review,automated'

      - name: Send PR Details
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
        with:
          action: 'send-message'
          api-key: ${{ secrets.DEVIN_API_KEY }}
          session-id: ${{ steps.create-session.outputs.session-id }}
          message: 'Focus on the changes in the authentication module'

      - name: Comment on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '🤖 Devin is reviewing this PR: ${{ steps.create-session.outputs.session-url }}'
            })
```

## Security Best Practices

1. **Never commit your API key** - Always use GitHub secrets
2. **Use least privilege** - Only grant necessary permissions
3. **Rotate keys regularly** - Update your API keys periodically
4. **Monitor usage** - Keep track of API calls in your Devin dashboard

## Troubleshooting

### Common Issues

#### Authentication Failed
- Verify your API key is correct and active
- Ensure the secret is properly configured in GitHub

#### Invalid Session ID
- Check that the session ID is correct
- Verify the session hasn't been deleted

#### File Upload Failed
- Ensure the file path is correct
- Check file permissions
- Verify file size is within limits

## Support

For issues and questions:
- [Devin API Documentation](https://docs.devin.ai/api-reference/overview)
- [GitHub Issues](https://github.com/samfert-codeium/DEVIN-GITHUB-ACTIONS/issues)
- [Devin Support](https://app.devin.ai/support)

## License

This action is available under the Apache-2.0 license.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
