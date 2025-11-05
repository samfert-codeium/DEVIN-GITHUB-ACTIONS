# Deployment Guide

This guide explains how to deploy and publish the Devin Playbook Sync GitHub Action.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Testing](#local-testing)
- [Publishing to GitHub Marketplace](#publishing-to-github-marketplace)
- [Versioning Strategy](#versioning-strategy)
- [Release Process](#release-process)
- [Update Process](#update-process)

## Prerequisites

Before deploying the action, ensure you have:

1. **Repository Access**: Write access to the `samfert-codeium/DEVIN-GITHUB-ACTIONS` repository
2. **Devin API Key**: For testing purposes
3. **Git Configured**: Your local git is set up with proper credentials

## Local Testing

### Method 1: Using act (Recommended)

[act](https://github.com/nektos/act) allows you to run GitHub Actions locally:

1. Install act:
   ```bash
   # macOS
   brew install act
   
   # Linux
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   
   # Windows
   choco install act-cli
   ```

2. Create a test workflow:
   ```bash
   mkdir -p .github/workflows
   cat > .github/workflows/test.yml << 'EOF'
   name: Test Action
   on: push
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: ./
           with:
             devin-api-key: ${{ secrets.DEVIN_API_KEY }}
             directory: './test-playbooks'
             dry-run: 'true'
   EOF
   ```

3. Create test markdown files:
   ```bash
   mkdir -p test-playbooks
   echo "# Test Playbook\nThis is a test playbook." > test-playbooks/test.md
   ```

4. Run the action locally:
   ```bash
   act push -s DEVIN_API_KEY=your-api-key-here
   ```

### Method 2: Testing in a Fork

1. Fork the repository to your personal account
2. Add your Devin API key to the fork's secrets
3. Create a test workflow and push changes
4. Monitor the Actions tab to see results

### Method 3: Direct Testing in Repository

1. Create a feature branch:
   ```bash
   git checkout -b test/action-validation
   ```

2. Add a test workflow:
   ```bash
   mkdir -p .github/workflows
   cat > .github/workflows/test-action.yml << 'EOF'
   name: Test Action
   on:
     push:
       branches: [test/*]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Test sync operation
           uses: ./
           with:
             devin-api-key: ${{ secrets.DEVIN_API_KEY }}
             directory: './test-playbooks'
             dry-run: 'true'
         - name: Test list operation
           uses: ./
           with:
             devin-api-key: ${{ secrets.DEVIN_API_KEY }}
             operation: 'list'
   EOF
   ```

3. Push and verify the action runs correctly

## Publishing to GitHub Marketplace

### Step 1: Prepare for Release

1. Ensure all files are in the repository:
   - `action.yml` (metadata)
   - `scripts/sync-playbooks.sh` (main script)
   - `README.md` (documentation)
   - `LICENSE` (if not already present)

2. Make the script executable:
   ```bash
   chmod +x scripts/sync-playbooks.sh
   ```

3. Commit all changes:
   ```bash
   git add action.yml scripts/ README.md DEPLOYMENT.md
   git commit -m "Prepare action for initial release"
   git push origin main
   ```

### Step 2: Create a Release

1. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Initial release of Devin Playbook Sync Action"
   git push origin v1.0.0
   ```

2. Create a major version tag for easier updates:
   ```bash
   git tag -a v1 -m "Version 1.x"
   git push origin v1
   ```

3. Go to GitHub repository → Releases → Draft a new release

4. Fill in the release details:
   - **Tag**: Select `v1.0.0`
   - **Title**: `v1.0.0 - Initial Release`
   - **Description**: Include release notes (see template below)
   - Check "Publish this Action to the GitHub Marketplace"
   - Select primary category: "Automation"
   - Add secondary category: "Publishing"

5. Click "Publish release"

### Release Notes Template

```markdown
## 🎉 Initial Release

### Features
- ✨ Scan directories for Markdown files
- 📤 Sync files as Devin playbooks via API
- 🔄 Support for all 5 Devin playbook operations (Create, List, Get, Update, Delete)
- 🧪 Dry-run mode for testing
- 📊 Detailed outputs (playbook IDs, counts, results)
- 🔒 Secure API key handling via GitHub secrets

### Supported Operations
- `sync` - Create playbooks from markdown files
- `list` - List all team playbooks
- `get` - Retrieve specific playbook
- `update` - Update existing playbook
- `delete` - Delete a playbook

### Usage
See [README.md](./README.md) for complete usage instructions.

### API Documentation
- [Devin API Reference](https://docs.devin.ai/api-reference/overview)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
```

## Versioning Strategy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (v2.0.0): Breaking changes
- **MINOR** (v1.1.0): New features, backward compatible
- **PATCH** (v1.0.1): Bug fixes, backward compatible

### Version Tags

Users can reference the action in three ways:

```yaml
# Specific version (recommended for production)
uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1.0.0

# Major version (gets latest v1.x.x)
uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@v1

# Latest (not recommended for production)
uses: samfert-codeium/DEVIN-GITHUB-ACTIONS@main
```

## Release Process

### For New Features (Minor Version)

1. Develop feature in a feature branch
2. Update README.md with new capabilities
3. Test thoroughly
4. Merge to main
5. Create new tags:
   ```bash
   git checkout main
   git pull
   git tag -a v1.1.0 -m "Add [feature name]"
   git push origin v1.1.0
   
   # Update major version tag
   git tag -fa v1 -m "Update v1 to v1.1.0"
   git push origin v1 --force
   ```
6. Create GitHub release with changelog

### For Bug Fixes (Patch Version)

1. Fix bug in a bugfix branch
2. Update tests if needed
3. Merge to main
4. Create new tags:
   ```bash
   git checkout main
   git pull
   git tag -a v1.0.1 -m "Fix [bug description]"
   git push origin v1.0.1
   
   # Update major version tag
   git tag -fa v1 -m "Update v1 to v1.0.1"
   git push origin v1 --force
   ```
5. Create GitHub release with bugfix notes

### For Breaking Changes (Major Version)

1. Plan and document breaking changes
2. Update README.md with migration guide
3. Test extensively
4. Merge to main
5. Create new tags:
   ```bash
   git checkout main
   git pull
   git tag -a v2.0.0 -m "Major version 2 with breaking changes"
   git push origin v2.0.0
   git tag -a v2 -m "Version 2.x"
   git push origin v2
   ```
6. Create GitHub release with detailed migration guide

## Update Process

### Updating the Action Code

1. Make changes to `action.yml` or `scripts/sync-playbooks.sh`
2. Update README.md if behavior changes
3. Test changes locally or in a feature branch
4. Follow the release process above

### Updating Dependencies

This action is self-contained and has minimal dependencies:
- **bash**: System default
- **curl**: Pre-installed on GitHub runners
- **jq**: Pre-installed on GitHub runners

If you need to add dependencies:
1. Update the action to install them in a setup step
2. Document the new requirement in README.md
3. Test on all supported runner types (ubuntu-latest, macos-latest, windows-latest)

## Best Practices

### Before Publishing

- [ ] Test all operation modes (sync, list, get, update, delete)
- [ ] Test with various directory structures
- [ ] Test error handling (invalid API key, network issues, etc.)
- [ ] Verify dry-run mode works correctly
- [ ] Check documentation is up-to-date
- [ ] Ensure scripts have proper permissions (`chmod +x`)
- [ ] Verify branding icons display correctly

### After Publishing

- [ ] Test the action using the marketplace version
- [ ] Monitor GitHub Issues for bug reports
- [ ] Update documentation based on user feedback
- [ ] Keep the action up-to-date with Devin API changes

## Monitoring

After deployment, monitor:

1. **GitHub Insights**: Track action usage and popularity
2. **Issues & Discussions**: Respond to user questions and bug reports
3. **Devin API Changes**: Update action when API changes
4. **Security Advisories**: Address any security vulnerabilities promptly

## Rolling Back

If a release has critical issues:

1. Update major version tag to previous working version:
   ```bash
   git tag -fa v1 -m "Rollback to v1.0.0"
   git push origin v1 --force
   ```

2. Create a new release explaining the rollback
3. Fix the issue and release a new patch version

## Support

For questions or issues:
- Open an issue in the repository
- Check existing documentation
- Review GitHub Actions logs for debugging

## References

- [GitHub Actions: Creating Actions](https://docs.github.com/en/actions/creating-actions)
- [Publishing Actions to Marketplace](https://docs.github.com/en/actions/creating-actions/publishing-actions-in-github-marketplace)
- [Devin API Documentation](https://docs.devin.ai/api-reference/overview)
- [Semantic Versioning](https://semver.org/)
