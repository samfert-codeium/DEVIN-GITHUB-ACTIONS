# Devin Playbook Scanner

A GitHub Action that scans a directory for Markdown (`.md`) files and automatically creates Devin playbooks from them using the Devin API.

## Features

- 📁 Recursively scans directories for `.md` files
- 📚 Creates Devin playbooks automatically using the Devin API
- 📊 Reports summary statistics (created, failed)
- 🔍 Returns created playbook IDs for downstream workflow steps
- ⚠️ Handles errors gracefully with detailed logging

## Usage

### Basic Example

```yaml
name: Create Playbooks from Markdown

on:
  push:
    branches: [main]
    paths:
      - 'playbooks/**/*.md'
  workflow_dispatch:

jobs:
  create-playbooks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Scan and create playbooks
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/md-playbook-scanner@v1
        with:
          directory: './playbooks'
          api-key: ${{ secrets.DEVIN_API_KEY }}
```

### Advanced Example with Output Usage

```yaml
name: Create and List Playbooks

on:
  workflow_dispatch:
    inputs:
      playbook-directory:
        description: 'Directory to scan for playbooks'
        required: true
        default: './docs/playbooks'

jobs:
  create-playbooks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Scan and create playbooks
        id: scanner
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/md-playbook-scanner@v1
        with:
          directory: ${{ github.event.inputs.playbook-directory }}
          api-key: ${{ secrets.DEVIN_API_KEY }}
      
      - name: Display results
        run: |
          echo "Playbooks created: ${{ steps.scanner.outputs.playbooks-created }}"
          echo "Playbooks failed: ${{ steps.scanner.outputs.playbooks-failed }}"
          echo "Playbook IDs: ${{ steps.scanner.outputs.playbook-ids }}"
      
      - name: Notify on success
        if: steps.scanner.outputs.playbooks-created > 0
        run: echo "Successfully created ${{ steps.scanner.outputs.playbooks-created }} playbooks!"
      
      - name: Fail on errors
        if: steps.scanner.outputs.playbooks-failed > 0
        run: exit 1
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `directory` | Directory path to scan for `.md` files (relative to repository root or absolute path) | Yes | - |
| `api-key` | Devin API key for authentication. Should be stored as a GitHub secret | Yes | - |

## Outputs

| Output | Description | Type |
|--------|-------------|------|
| `playbooks-created` | Number of playbooks successfully created | Number |
| `playbooks-failed` | Number of playbooks that failed to create | Number |
| `playbook-ids` | JSON array of created playbook IDs | JSON Array |

## Prerequisites

### 1. Devin API Key

You need a Devin API key to use this action. To obtain one:

1. Go to [Devin Settings](https://app.devin.ai/settings/api-keys)
2. Generate a new API key
3. Add it to your repository secrets as `DEVIN_API_KEY`:
   - Go to your repository on GitHub
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `DEVIN_API_KEY`
   - Value: Your Devin API key

### 2. Markdown Files

Organize your Markdown files in a directory structure. Each `.md` file will become a playbook:

```
playbooks/
├── deployment.md
├── code-review.md
└── testing/
    ├── unit-tests.md
    └── integration-tests.md
```

**Playbook Naming Convention:**
- The filename (without `.md` extension) becomes the playbook title
- Example: `deployment.md` → playbook title: "deployment"
- The file content becomes the playbook body/instructions

## How It Works

1. The action scans the specified directory recursively for all `.md` files
2. For each `.md` file found:
   - Extracts the filename (without extension) as the playbook title
   - Reads the file content as the playbook body
   - Creates a new playbook via the Devin API
3. Reports statistics and returns created playbook IDs
4. Fails the workflow if any playbooks failed to create

## Error Handling

The action will:
- ✅ Continue processing all files even if some fail
- ✅ Log detailed error messages for failures
- ✅ Exit with non-zero code if any playbooks failed to create
- ✅ Report summary statistics at the end

Common failure scenarios:
- Invalid API key (HTTP 401)
- Missing permissions (HTTP 403)
- Empty or invalid directory path
- Network issues connecting to Devin API
- Invalid file content

## Limitations

- Only `.md` files are processed (case-sensitive)
- Empty filenames or content may cause failures
- Requires valid Devin API key with playbook creation permissions
- API rate limits may apply for large numbers of files

## Examples Directory

See the [examples](./examples/) directory for complete workflow examples.

## Related Actions

- [devin-action](../devin-action/) - Full-featured Devin API client for sessions, secrets, knowledge, and playbooks

## Support

For issues or questions:
- GitHub Issues: [DEVIN-GITHUB-ACTIONS Repository](https://github.com/samfert-codeium/DEVIN-GITHUB-ACTIONS/issues)
- Devin API Documentation: [https://docs.devin.ai/api-reference/overview](https://docs.devin.ai/api-reference/overview)
- Email: support@cognition.ai

## License

See the main repository [LICENSE](../LICENSE) file.
