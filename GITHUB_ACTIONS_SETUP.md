# GitHub Actions Setup Instructions

## Required Repository Settings

To enable all workflow features, you need to configure the following settings in your GitHub repository:

### 1. Allow GitHub Actions to Create Pull Requests

**Path:** Settings → Actions → General → Workflow permissions

1. Go to your repository on GitHub
2. Click **Settings** (top right)
3. Click **Actions** → **General** (left sidebar)
4. Scroll down to **Workflow permissions**
5. Select **"Read and write permissions"**
6. Check the box: **"Allow GitHub Actions to create and approve pull requests"**
7. Click **Save**

### 2. Configure Branch Protection (Optional but Recommended)

**Path:** Settings → Branches

For the `main` or `master` branch:
- Require pull request reviews before merging
- Require status checks to pass before merging
  - Select: `terraform-validate`, `security-scan`, `code-quality`
- Require branches to be up to date before merging

### 3. Add Required Secrets (if needed)

**Path:** Settings → Secrets and variables → Actions

Optional secrets for enhanced functionality:
- `AWS_OIDC_ROLE` - AWS IAM role ARN for OIDC authentication (already configured)
- `SLACK_WEBHOOK_URL` - For Slack notifications on releases
- `TEAMS_WEBHOOK_URL` - For Microsoft Teams notifications

## Workflow Features

Once configured, the following workflows will work automatically:

### Automated Workflows
- ✅ **CI Pipeline** - Runs on every push/PR
- ✅ **Security Scans** - Runs security checks and posts results
- ✅ **PR Validation** - Validates PRs with Terraform plan
- ✅ **Auto Format** - Automatically formats code
- ✅ **Dependency Updates** - Weekly dependency update PRs (requires setting above)
- ✅ **Release Pipeline** - Creates releases with tags

### Manual Workflows
- 🔧 **Release** - Can be triggered manually via workflow_dispatch
- 🔧 **Dependency Updates** - Can be triggered manually

## Troubleshooting

### "GitHub Actions is not permitted to create or approve pull requests"
- Follow step 1 above to enable PR creation

### "Permission denied to github-actions[bot]"
- Ensure "Read and write permissions" is selected in Workflow permissions

### Rate Limiting Issues
- The workflows use `GITHUB_TOKEN` to avoid rate limits
- If issues persist, consider creating a Personal Access Token (PAT)

## Verification

After configuring the settings:
1. Trigger the dependency update workflow manually
2. Check that it creates a PR successfully
3. Verify all CI checks run on the PR

## Support

For issues or questions:
- Check workflow run logs in the Actions tab
- Review the workflow files in `.github/workflows/`
- Consult GitHub Actions documentation: https://docs.github.com/en/actions
