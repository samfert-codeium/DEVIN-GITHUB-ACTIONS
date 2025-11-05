# Devin Playbook Sync Action

A GitHub Action that scans directories for Markdown files and syncs them as Devin playbooks using the [Devin API](https://docs.devin.ai/api-reference/overview). This action supports all Devin playbook operations including create, list, get, update, and delete.

## Features

- 📁 **Automatic Discovery**: Scans directories for `.md` files
- 🔄 **Full API Support**: Supports all 5 Devin playbook API operations
- 🎯 **Flexible Operations**: Create, list, get, update, and delete playbooks
- 🔒 **Secure**: Uses GitHub secrets for API key management
- 🚀 **Easy to Use**: Simple configuration with sensible defaults
- 🧪 **Dry Run Mode**: Test without making actual API calls
- 📊 **Detailed Output**: Returns playbook IDs and operation results

## Supported Operations

- **sync** (default): Scan directory for `.md` files and create playbooks
- **list**: List all team playbooks
- **get**: Retrieve a specific playbook
- **update**: Update an existing playbook
- **delete**: Delete a playbook

## Usage

### Prerequisites

1. Get your Devin API key from [Devin Settings](https://app.devin.ai/settings)
2. Add the API key to your repository secrets as `DEVIN_API_KEY`

### Basic Usage - Sync Markdown Files

Create a workflow file (e.g., `.github/workflows/sync-playbooks.yml`):

```yaml
name: Sync Playbooks

on:
  push:
    branches: [main]
    paths:
      - 'playbooks/**/*.md'
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Sync playbooks to Devin
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
        with:
          devin-api-key: ${{ secrets.DEVIN_API_KEY }}
          directory: './playbooks'
          operation: 'sync'
```

### List All Playbooks

```yaml
- name: List all playbooks
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    operation: 'list'
```

### Get a Specific Playbook

```yaml
- name: Get playbook
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    operation: 'get'
    playbook-id: 'your-playbook-id'
```

### Update a Playbook

```yaml
- name: Update playbook
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    operation: 'update'
    playbook-id: 'your-playbook-id'
    playbook-title: 'Updated Title'
    playbook-body: 'Updated content...'
    playbook-macro: '!deploy'
```

### Delete a Playbook

```yaml
- name: Delete playbook
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    operation: 'delete'
    playbook-id: 'your-playbook-id'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `devin-api-key` | Devin API key for authentication | Yes | - |
| `operation` | Operation to perform: `sync`, `list`, `get`, `update`, `delete` | No | `sync` |
| `directory` | Directory to scan for `.md` files (used with `sync`) | No | `.` |
| `playbook-id` | Playbook ID (required for `get`, `update`, `delete`) | No | - |
| `playbook-title` | Title for the playbook (used with `update`) | No | - |
| `playbook-body` | Body/content for the playbook (used with `update`) | No | - |
| `playbook-macro` | Optional macro shortcut (e.g., `!deploy`) | No | - |
| `api-base-url` | Base URL for the Devin API | No | `https://api.devin.ai` |
| `recursive` | Recursively scan subdirectories | No | `true` |
| `dry-run` | Run without making actual API calls | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `playbook-ids` | Comma-separated list of created/updated playbook IDs |
| `playbooks-count` | Number of playbooks processed |
| `operation-result` | Result of the operation in JSON format |

## Advanced Examples

### Sync with Custom Configuration

```yaml
- name: Sync playbooks with custom settings
  id: sync
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    directory: './docs/playbooks'
    recursive: 'true'
    playbook-macro: '!auto'

- name: Display results
  run: |
    echo "Created playbooks: ${{ steps.sync.outputs.playbook-ids }}"
    echo "Total count: ${{ steps.sync.outputs.playbooks-count }}"
```

### Dry Run Before Syncing

```yaml
- name: Test sync (dry run)
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    directory: './playbooks'
    dry-run: 'true'
```

### Complete Workflow Example

```yaml
name: Playbook Management

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      operation:
        description: 'Operation to perform'
        required: true
        type: choice
        options:
          - sync
          - list
        default: 'list'

jobs:
  manage-playbooks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Dry run on PR
        if: github.event_name == 'pull_request'
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
        with:
          devin-api-key: ${{ secrets.DEVIN_API_KEY }}
          directory: './playbooks'
          dry-run: 'true'
      
      - name: Sync on push to main
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
        with:
          devin-api-key: ${{ secrets.DEVIN_API_KEY }}
          directory: './playbooks'
      
      - name: Manual operation
        if: github.event_name == 'workflow_dispatch'
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
        with:
          devin-api-key: ${{ secrets.DEVIN_API_KEY }}
          operation: ${{ github.event.inputs.operation }}
          directory: './playbooks'
```

## Markdown File Format

Your markdown files should contain the playbook content. The filename (without `.md` extension) will be used as the playbook title.

Example file structure:
```
playbooks/
├── setup-dev-environment.md
├── deploy-to-production.md
└── code-review-checklist.md
```

Example `setup-dev-environment.md`:
```markdown
# Development Environment Setup

This playbook guides you through setting up the development environment.

## Prerequisites
- Node.js 18+
- Docker installed
- Git configured

## Steps
1. Clone the repository
2. Install dependencies: `npm install`
3. Configure environment variables
4. Start development server: `npm run dev`
```

## API Documentation

This action integrates with the following Devin API endpoints:

- **POST /v1/playbooks** - Create a new playbook
- **GET /v1/playbooks** - List all playbooks
- **GET /v1/playbooks/{id}** - Get a specific playbook
- **PUT /v1/playbooks/{id}** - Update a playbook
- **DELETE /v1/playbooks/{id}** - Delete a playbook

For detailed API documentation, visit: https://docs.devin.ai/api-reference/overview

## Error Handling

The action will fail if:
- Invalid API key provided
- Required inputs are missing
- API requests fail (network issues, authentication, etc.)
- No markdown files found in the specified directory (warning only)

Check the action logs for detailed error messages and troubleshooting information.

## Security

- Always store your Devin API key in GitHub secrets, never commit it to the repository
- Use repository secrets: Settings → Secrets and variables → Actions → New repository secret
- The API key is passed securely to the action through environment variables

## Troubleshooting

### Action fails with "unauthorized"
- Verify your API key is correct
- Ensure the secret name matches what's used in the workflow

### No playbooks created
- Check that `.md` files exist in the specified directory
- Verify the `directory` path is correct
- Enable `dry-run: 'true'` to test without API calls

### API rate limiting
- The Devin API may have rate limits
- Consider adding delays between bulk operations
- Contact Devin support for rate limit information

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Support

- [Devin Documentation](https://docs.devin.ai/)
- [Devin API Reference](https://docs.devin.ai/api-reference/overview)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Author

Created by Sam Fertig ([@samfert-codeium](https://github.com/samfert-codeium))
