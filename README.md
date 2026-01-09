# DEVIN-GITHUB-ACTIONS

A collection of GitHub Actions for integrating with the Devin API. This repository provides tools to automate Devin session management, secrets handling, knowledge base operations, and playbook management directly from your GitHub workflows.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation and Configuration](#installation-and-configuration)
- [Quick Start](#quick-start)
- [Available Actions](#available-actions)
- [Features](#features)
- [Examples](#examples)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

## Overview

DEVIN-GITHUB-ACTIONS enables seamless integration between GitHub workflows and the Devin AI assistant. With this action, you can programmatically create Devin sessions to automate code reviews, bug fixes, feature implementations, and other development tasks as part of your CI/CD pipeline.

The action communicates with the Devin API using a shell script that handles authentication, request building, and response parsing. It supports all major Devin API endpoints including session management, secrets, knowledge base, and playbooks.

## Project Structure

```
DEVIN-GITHUB-ACTIONS/
├── README.md                          # This file - main project documentation
├── devin-action/                      # Main GitHub Action directory
│   ├── action.yml                     # GitHub Action definition and inputs/outputs
│   ├── README.md                      # Detailed action documentation
│   ├── DEPLOYMENT.md                  # Deployment and publishing guide
│   ├── scripts/
│   │   └── devin-api.sh              # Shell script for Devin API interactions
│   └── examples/
│       └── example-workflow.yml       # Example GitHub workflow
```

## Requirements

Before using this action, ensure you have the following:

**GitHub Requirements:**
- A GitHub repository with Actions enabled
- Permission to add secrets to your repository
- A workflow file (`.github/workflows/*.yml`)

**Devin Requirements:**
- An active Devin account
- A Devin API key (obtain from [Devin settings](https://app.devin.ai/settings))

**Runtime Dependencies (automatically available in GitHub Actions runners):**
- `bash` (version 4.0 or higher)
- `curl` (for HTTP requests)
- `jq` (for JSON parsing)

## Installation and Configuration

### Step 1: Obtain Your Devin API Key

1. Log in to your Devin account at [app.devin.ai](https://app.devin.ai)
2. Navigate to Settings
3. Generate or copy your API key

### Step 2: Add the API Key to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Name: `DEVIN_API_KEY`
5. Value: Paste your Devin API key
6. Click **Add secret**

### Step 3: Create a Workflow File

Create a new file in your repository at `.github/workflows/devin.yml` (or any name ending in `.yml`):

```yaml
name: Devin Integration

on:
  workflow_dispatch:
    inputs:
      task:
        description: 'Task for Devin'
        required: true

jobs:
  run-devin:
    runs-on: ubuntu-latest
    steps:
      - name: Create Devin Session
        uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
        with:
          action: 'create-session'
          api-key: ${{ secrets.DEVIN_API_KEY }}
          prompt: ${{ github.event.inputs.task }}
```

## Quick Start

Here's a minimal example to create a Devin session:

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

- name: Display Session URL
  run: echo "Session URL: ${{ steps.create-session.outputs.session-url }}"
```

## Available Actions

The action supports the following operations:

### Session Management
| Action | Description |
|--------|-------------|
| `create-session` | Create a new Devin session with a task prompt |
| `send-message` | Send a follow-up message to an existing session |
| `get-session` | Retrieve details about a specific session |
| `list-sessions` | List all sessions associated with your API key |
| `upload-files` | Upload files to a session for Devin to access |
| `update-tags` | Update the tags on an existing session |

### Secrets Management
| Action | Description |
|--------|-------------|
| `list-secrets` | List all stored secrets |
| `create-secret` | Create a new secret for use in sessions |
| `delete-secret` | Delete an existing secret |

### Knowledge Management
| Action | Description |
|--------|-------------|
| `list-knowledge` | List all knowledge entries |
| `create-knowledge` | Create a new knowledge entry |
| `update-knowledge` | Update an existing knowledge entry |
| `delete-knowledge` | Delete a knowledge entry |

### Playbooks Management
| Action | Description |
|--------|-------------|
| `list-playbooks` | List all playbooks |
| `create-playbook` | Create a new playbook |
| `get-playbook` | Get details of a specific playbook |
| `update-playbook` | Update an existing playbook |
| `delete-playbook` | Delete a playbook |

## Features

**Session Management:** Create and manage Devin sessions programmatically. Start automated code reviews, bug fixes, or feature implementations directly from your CI/CD pipeline.

**File Operations:** Upload files to sessions so Devin can access test results, logs, configuration files, or any other resources needed for the task.

**Tagging System:** Organize sessions with tags for easy filtering and categorization. Update tags as sessions progress through different stages.

**Secrets Management:** Securely store and manage credentials that Devin can use during sessions, such as API keys, database passwords, or service tokens.

**Knowledge Base:** Create and maintain a knowledge base that Devin can reference. Store documentation, coding guidelines, architecture decisions, or any information relevant to your projects.

**Playbooks:** Define reusable workflows and instructions that Devin can follow for specific types of tasks, ensuring consistent approaches across similar problems.

## Examples

See the [examples directory](./devin-action/examples/) for complete workflow examples, including:

- **Basic Session Creation:** Simple workflow to create a Devin session
- **PR Review Automation:** Automatically trigger Devin to review pull requests
- **Scheduled Tasks:** Run Devin sessions on a schedule for maintenance tasks

For detailed usage instructions and all available inputs/outputs, see the [devin-action README](./devin-action/README.md).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. When contributing:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

- [Devin API Documentation](https://docs.devin.ai/api-reference/overview)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Issues](https://github.com/samfert-codeium/DEVIN-GITHUB-ACTIONS/issues)

## License

Apache-2.0
