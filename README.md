# DEVIN-GITHUB-ACTIONS

A collection of GitHub Actions for integrating with the Devin API.

## Available Actions

### Playbook Sync Action (Root)

A GitHub Action that scans directories for Markdown files and syncs them as Devin playbooks using the Devin API. Supports all Devin playbook operations including create, list, get, update, and delete.

📖 **Documentation**: See below for detailed usage instructions

🚀 **Quick Start**:

```yaml
- name: Sync playbooks to Devin
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1
  with:
    devin-api-key: ${{ secrets.DEVIN_API_KEY }}
    directory: './playbooks'
    operation: 'sync'
```

**Features:**
- 📁 Automatic discovery of `.md` files
- 🔄 Full API support for all 5 playbook operations (create, list, get, update, delete)
- 🧪 Dry run mode for testing
- 📊 Detailed outputs with playbook IDs and counts

**Supported Operations:**
- `sync` - Scan directory and create playbooks from `.md` files
- `list` - List all team playbooks
- `get` - Retrieve a specific playbook
- `update` - Update an existing playbook
- `delete` - Delete a playbook

### Devin API Action

A comprehensive GitHub Action for interacting with the Devin API to create and manage Devin sessions programmatically from your GitHub workflows.

📂 **Location**: [`devin-action/`](./devin-action/)

📖 **Documentation**: See [devin-action/README.md](./devin-action/README.md) for detailed usage instructions

🚀 **Quick Start**:

```yaml
- name: Create Devin Session
  uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
  id: create-session
  with:
    action: 'create-session'
    api-key: ${{ secrets.DEVIN_API_KEY }}
    prompt: 'Fix the failing unit tests'
    title: 'Automated Bug Fix'
    tags: 'bug-fix,automated'
```

**Features:**
- **Session Management**: Create sessions, send messages, get status, list sessions
- **File Operations**: Upload files to sessions
- **Tagging**: Update session tags
- **Secrets Management**: Create, list, and delete secrets
- **Knowledge Management**: Manage knowledge base entries
- **Playbooks Management**: Create and manage playbooks

## Prerequisites

1. Get a Devin API key from your [Devin settings page](https://app.devin.ai/settings)
2. Store it as a GitHub secret (recommended name: `DEVIN_API_KEY`)

## Examples

See [devin-action/examples/](./devin-action/examples/) for Devin API Action workflow examples.

See [test-playbooks/](./test-playbooks/) for example playbook markdown files.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

- [Devin API Documentation](https://docs.devin.ai/api-reference/overview)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Issues](https://github.com/samfert-codeium/DEVIN-GITHUB-ACTIONS/issues)

## License

- Playbook Sync Action: MIT License - see [LICENSE](./LICENSE)
- Devin API Action: Apache-2.0
