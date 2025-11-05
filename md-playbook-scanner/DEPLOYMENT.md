# Deployment Guide - Devin Playbook Scanner

This guide explains how to test, version, and deploy the Devin Playbook Scanner GitHub Action.

## Table of Contents

1. [Testing Locally](#testing-locally)
2. [Testing in CI](#testing-in-ci)
3. [Versioning Strategy](#versioning-strategy)
4. [Release Process](#release-process)
5. [Publishing to GitHub Marketplace](#publishing-to-github-marketplace)
6. [Rollback Procedures](#rollback-procedures)

---

## Testing Locally

### Prerequisites

- [act](https://github.com/nektos/act) - Tool to run GitHub Actions locally
- Docker installed and running
- Valid Devin API key

### Using `act`

Create a test workflow file `.github/workflows/test-md-scanner-local.yml`:

```yaml
name: Test MD Scanner Locally

on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./md-playbook-scanner
        with:
          directory: './test-playbooks'
          api-key: ${{ secrets.DEVIN_API_KEY }}
```

Create test markdown files:

```bash
mkdir -p test-playbooks
echo "# Test Playbook 1\nThis is a test playbook." > test-playbooks/test1.md
echo "# Test Playbook 2\nAnother test playbook." > test-playbooks/test2.md
```

Run with `act`:

```bash
# Run the workflow with act
act workflow_dispatch -s DEVIN_API_KEY=your_api_key_here
```

### Manual Testing

You can also test the script directly:

```bash
# Make the script executable
chmod +x md-playbook-scanner/scripts/scan-and-create.sh

# Create test directory
mkdir -p test-playbooks
echo "# Deployment\nDeploy the application" > test-playbooks/deployment.md

# Set environment variable for GITHUB_OUTPUT
export GITHUB_OUTPUT=$(mktemp)

# Run the script
./md-playbook-scanner/scripts/scan-and-create.sh \
  "test-playbooks" \
  "your_devin_api_key"

# Check outputs
cat $GITHUB_OUTPUT
```

---

## Testing in CI

### Automated Testing Workflow

Create `.github/workflows/test-md-scanner.yml`:

```yaml
name: Test MD Playbook Scanner

on:
  pull_request:
    paths:
      - 'md-playbook-scanner/**'
  push:
    branches:
      - main
    paths:
      - 'md-playbook-scanner/**'
  workflow_dispatch:

jobs:
  test-scanner:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Create test playbooks
        run: |
          mkdir -p test-playbooks/subfolder
          echo "# Test Deployment" > test-playbooks/deployment.md
          echo "Deploy to production" >> test-playbooks/deployment.md
          echo "# Test Review" > test-playbooks/code-review.md
          echo "Review code changes" >> test-playbooks/code-review.md
          echo "# Nested Test" > test-playbooks/subfolder/nested.md
          echo "Nested playbook" >> test-playbooks/subfolder/nested.md
      
      - name: Run MD Playbook Scanner
        id: scanner
        uses: ./md-playbook-scanner
        with:
          directory: './test-playbooks'
          api-key: ${{ secrets.DEVIN_API_KEY }}
      
      - name: Verify outputs
        run: |
          echo "Created: ${{ steps.scanner.outputs.playbooks-created }}"
          echo "Failed: ${{ steps.scanner.outputs.playbooks-failed }}"
          echo "IDs: ${{ steps.scanner.outputs.playbook-ids }}"
          
          # Verify at least 3 playbooks were created
          if [ "${{ steps.scanner.outputs.playbooks-created }}" -lt 3 ]; then
            echo "Error: Expected at least 3 playbooks created"
            exit 1
          fi
          
          # Verify no failures
          if [ "${{ steps.scanner.outputs.playbooks-failed }}" -gt 0 ]; then
            echo "Error: Some playbooks failed to create"
            exit 1
          fi
      
      - name: Test with non-existent directory
        id: test-invalid
        continue-on-error: true
        uses: ./md-playbook-scanner
        with:
          directory: './non-existent-dir'
          api-key: ${{ secrets.DEVIN_API_KEY }}
      
      - name: Verify error handling
        if: steps.test-invalid.outcome != 'failure'
        run: |
          echo "Error: Action should have failed with non-existent directory"
          exit 1
```

### Required Secrets

Add the following secret to your repository:
- `DEVIN_API_KEY`: Your Devin API key from [https://app.devin.ai/settings/api-keys](https://app.devin.ai/settings/api-keys)

---

## Versioning Strategy

This action follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (v2.0.0): Breaking changes (incompatible API changes)
- **MINOR** version (v1.1.0): New features (backward-compatible)
- **PATCH** version (v1.0.1): Bug fixes (backward-compatible)

### Version Tags

We maintain multiple tag types:

1. **Specific version tags**: `v1.0.0`, `v1.0.1`, `v1.1.0`
   - Point to exact commits
   - Never moved once created
   - Recommended for production use requiring stability

2. **Major version tags**: `v1`, `v2`
   - Point to the latest stable release within that major version
   - Updated with each new minor/patch release
   - Recommended for users who want automatic updates

3. **Branch references**: `@main`
   - Points to the latest code
   - May include unreleased features
   - Not recommended for production

---

## Release Process

### 1. Prepare Release Branch

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create release branch
git checkout -b release/v1.0.0
```

### 2. Update Documentation

- Update version numbers in README.md examples
- Update CHANGELOG.md with release notes
- Verify all documentation is current

### 3. Test Thoroughly

```bash
# Run local tests
act workflow_dispatch -s DEVIN_API_KEY=your_key

# Push and verify CI passes
git push origin release/v1.0.0
```

### 4. Create and Push Tags

```bash
# Create specific version tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial release of MD Playbook Scanner"
git push origin v1.0.0

# Update or create major version tag
git tag -fa v1 -m "Update v1 to v1.0.0"
git push origin v1 --force
```

### 5. Merge to Main

```bash
git checkout main
git merge release/v1.0.0
git push origin main
```

### 6. Create GitHub Release

1. Go to your repository on GitHub
2. Navigate to "Releases" → "Create a new release"
3. Select the tag (e.g., `v1.0.0`)
4. Fill in release details:
   - **Title**: `v1.0.0 - Initial Release`
   - **Description**: Include features, bug fixes, breaking changes
5. Mark as latest release
6. Publish release

---

## Publishing to GitHub Marketplace

### Prerequisites

- Repository must be public
- Action must have proper metadata in `action.yml`:
  - `name`
  - `description`
  - `author`
  - `branding` (icon and color)

### Steps

1. Go to your repository on GitHub
2. Navigate to "Releases"
3. When creating a release, check "Publish this Action to the GitHub Marketplace"
4. Choose a category (e.g., "Continuous Integration")
5. Review and accept the terms
6. Publish the release

### Marketplace Listing

Once published, your action will appear at:
```
https://github.com/marketplace/actions/devin-playbook-scanner
```

Users can then reference it as:
```yaml
uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/md-playbook-scanner@v1
```

---

## Rollback Procedures

### Rolling Back a Version

If a release has critical issues:

#### 1. Immediate Rollback (Major Version Tag)

```bash
# Rollback v1 tag to previous stable version (e.g., v1.0.1)
git tag -fa v1 v1.0.1
git push origin v1 --force
```

This immediately affects users referencing `@v1`.

#### 2. Create Hotfix Release

```bash
# Create hotfix branch from previous stable version
git checkout -b hotfix/v1.0.3 v1.0.2

# Make fixes
# ... edit files ...

# Commit and tag
git commit -am "Fix critical bug"
git tag -a v1.0.3 -m "Hotfix: Fix critical bug"
git push origin v1.0.3

# Update major version tag
git tag -fa v1 v1.0.3
git push origin v1 --force

# Merge back to main
git checkout main
git merge hotfix/v1.0.3
git push origin main
```

#### 3. Deprecate Problematic Version

In GitHub Release notes, mark the problematic version as deprecated:

```markdown
## ⚠️ DEPRECATED - Do Not Use

This release contains a critical bug and has been superseded by v1.0.3.
Please upgrade immediately.

**Issue**: [Description of the problem]
**Fix**: Released in v1.0.3
```

### Testing Rollback

Before rolling back in production:

```bash
# Test the previous version locally
git checkout v1.0.1
act workflow_dispatch -s DEVIN_API_KEY=your_key

# Verify it works as expected
```

---

## Troubleshooting

### Common Issues

1. **Script not executable**
   - Solution: Ensure script has execute permissions before committing
   ```bash
   chmod +x md-playbook-scanner/scripts/scan-and-create.sh
   git add md-playbook-scanner/scripts/scan-and-create.sh
   ```

2. **API authentication failures**
   - Check API key is valid
   - Verify secret name matches in workflow (`DEVIN_API_KEY`)
   - Test API key with curl manually

3. **Path issues in workflows**
   - Use relative paths from repository root
   - Check `directory` input is accessible from workflow context

4. **jq not found**
   - Default GitHub runners include jq
   - For self-hosted runners: `apt-get install jq`

---

## Best Practices

1. **Always test before releasing**
   - Test locally with `act`
   - Test in CI with pull requests
   - Test specific version tags before promoting to major version

2. **Use semantic versioning correctly**
   - Breaking changes require major version bump
   - New features require minor version bump
   - Bug fixes require patch version bump

3. **Document changes**
   - Maintain CHANGELOG.md
   - Write clear release notes
   - Document breaking changes prominently

4. **Communicate with users**
   - Announce breaking changes in advance
   - Provide migration guides
   - Deprecate features before removing them

---

## Support

For deployment issues or questions:
- GitHub Issues: [Report an issue](https://github.com/samfert-codeium/DEVIN-GITHUB-ACTIONS/issues)
- Email: support@cognition.ai
