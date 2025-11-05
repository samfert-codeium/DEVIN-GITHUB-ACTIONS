# Deploying the Devin API GitHub Action

This guide explains how to deploy and publish the Devin API GitHub Action for use in your workflows.

## Table of Contents

1. [Local Testing](#local-testing)
2. [Publishing to GitHub](#publishing-to-github)
3. [Versioning Strategy](#versioning-strategy)
4. [GitHub Marketplace](#github-marketplace)

## Local Testing

Before publishing, test the action locally using [act](https://github.com/nektos/act) or by referencing it from a test workflow.

### Testing with a Local Workflow

1. Create a test workflow in `.github/workflows/test-devin-action.yml`:

```yaml
name: Test Devin Action

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Test Create Session
        uses: ./devin-action
        id: test-session
        with:
          action: 'create-session'
          api-key: ${{ secrets.DEVIN_API_KEY }}
          prompt: 'This is a test session'
          title: 'Test Session'

      - name: Verify Output
        run: |
          echo "Session ID: ${{ steps.test-session.outputs.session-id }}"
          if [ -z "${{ steps.test-session.outputs.session-id }}" ]; then
            echo "Error: No session ID returned"
            exit 1
          fi
```

2. Run the workflow manually from the GitHub Actions tab
3. Verify the outputs are correct

## Publishing to GitHub

### Option 1: Direct Repository Reference

Users can reference the action directly from your repository:

```yaml
- uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@main
```

Or reference a specific commit:

```yaml
- uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@abc123
```

### Option 2: Using Release Tags

For better version management, create releases:

1. **Create a new release branch** (if needed):
   ```bash
   git checkout -b release/v1
   ```

2. **Commit your changes**:
   ```bash
   git add devin-action/
   git commit -m "Release v1.0.0 of Devin API Action"
   ```

3. **Push to GitHub**:
   ```bash
   git push origin release/v1
   ```

4. **Create a release on GitHub**:
   - Go to your repository on GitHub
   - Click "Releases" → "Create a new release"
   - Create a tag (e.g., `v1.0.0`, `v1.0.1`)
   - Set the target to your release branch or main
   - Add release notes describing the features
   - Publish the release

5. **Create version aliases** (recommended):
   ```bash
   # Create major version tag
   git tag -fa v1 -m "Release v1"
   git push origin v1 --force
   ```

Now users can reference specific versions:

```yaml
# Use latest v1.x.x version
- uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@v1

# Use specific version
- uses: samfert-codeium/DEVIN-GITHUB-ACTIONS/devin-action@v1.0.0
```

## Versioning Strategy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version (v2.0.0): Breaking changes to inputs/outputs
- **MINOR** version (v1.1.0): New features, backward compatible
- **PATCH** version (v1.0.1): Bug fixes, backward compatible

### Example Version History

```
v1.0.0 - Initial release with core session management
v1.1.0 - Added secrets management support
v1.2.0 - Added knowledge and playbooks management
v1.2.1 - Fixed bug in file upload handling
v2.0.0 - Breaking: Changed input parameter names
```

### Maintaining Version Tags

When releasing a new minor or patch version, update the major version tag:

```bash
# After releasing v1.2.0
git tag -fa v1 -m "Release v1.2.0"
git push origin v1 --force
```

This allows users on `@v1` to automatically get non-breaking updates.

## GitHub Marketplace

To publish your action to the GitHub Marketplace:

1. **Ensure your action.yml has branding**:
   ```yaml
   branding:
     icon: 'cpu'
     color: 'blue'
   ```

2. **Add topics to your repository**:
   - Go to your repository settings
   - Add topics: `github-actions`, `devin-api`, `automation`

3. **Create a release** (as described above)

4. **Submit to Marketplace**:
   - When creating a release, check "Publish this Action to the GitHub Marketplace"
   - Ensure your README is comprehensive
   - Add a clear description
   - Choose appropriate categories

5. **Marketplace Guidelines**:
   - Must have a README with usage examples
   - Must have an action.yml with branding
   - Must be in a public repository
   - Must include a license

## Updating the Action

When making updates:

1. **Test changes locally** using a test workflow

2. **Update documentation**:
   - Update README.md with new features
   - Update examples if needed
   - Update DEPLOYMENT.md if deployment process changes

3. **Create a new release**:
   ```bash
   git add .
   git commit -m "Add feature XYZ"
   git push origin main
   
   # Create new version tag
   git tag v1.3.0
   git push origin v1.3.0
   
   # Update major version tag
   git tag -fa v1 -m "Release v1.3.0"
   git push origin v1 --force
   ```

4. **Create GitHub release**:
   - Document all changes in release notes
   - Mention breaking changes prominently
   - Provide migration guide if needed

## Security Considerations

1. **Secrets Handling**:
   - Never log API keys or secrets
   - Use GitHub's secret masking
   - Document secure usage patterns

2. **Dependencies**:
   - Keep dependencies minimal
   - Review any external dependencies
   - Consider security implications

3. **Input Validation**:
   - Validate all user inputs
   - Sanitize inputs before API calls
   - Handle errors gracefully

## Monitoring and Support

1. **Enable GitHub Discussions** for user questions

2. **Monitor GitHub Issues** for bug reports

3. **Set up GitHub Actions** for automated testing

4. **Document common issues** in README

## Rollback Procedure

If a release has critical issues:

1. **Revert the release**:
   ```bash
   # Point v1 tag back to previous stable version
   git tag -fa v1 v1.2.0
   git push origin v1 --force
   ```

2. **Mark the problematic release as pre-release** on GitHub

3. **Document the issue** in release notes

4. **Release a fix** as soon as possible

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Publishing Actions to Marketplace](https://docs.github.com/en/actions/creating-actions/publishing-actions-in-github-marketplace)
- [Devin API Documentation](https://docs.devin.ai/api-reference/overview)
