# GitHub Actions Troubleshooting Guide

## 🚨 Common Issues and Solutions

### 1. **"Resource not accessible by integration" Error**

**Error Message:**
```
RequestError [HttpError]: Resource not accessible by integration
Error: Unhandled error: HttpError: Resource not accessible by integration
status: 403
```

**Cause:** GitHub Actions doesn't have the required permissions to create or update PR comments.

**Solutions:**

#### Option A: Check Repository Settings (Recommended)
1. Go to your repository settings
2. Navigate to **Actions** → **General**
3. Under **Workflow permissions**, ensure:
   - ✅ **"Read and write permissions"** is selected, OR
   - ✅ **"Read repository contents and packages permissions"** with additional permissions enabled

#### Option B: Update Workflow Permissions
Ensure each job that needs to comment has proper permissions:

```yaml
jobs:
  job-name:
    permissions:
      contents: read
      pull-requests: write  # Required for PR comments
      issues: write        # Required for issue comments
```

#### Option C: Use Personal Access Token (Advanced)
If repository permissions can't be changed:

1. Create a Personal Access Token with `repo` scope
2. Add it as a repository secret (e.g., `PAT_TOKEN`)
3. Use it in workflows:
```yaml
- name: Comment on PR
  uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.PAT_TOKEN }}
```

### 2. **Terraform Command Not Found**

**Error Message:**
```
terraform: command not found
Error: Process completed with exit code 127
```

**Solution:** Add Terraform setup step:
```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: "1.6.0"
```

### 3. **Go Formatting Issues**

**Error Message:**
```
Go files are not formatted properly
```

**Solutions:**

#### Automatic Fix (Recommended)
The workflows now auto-format Go files. If issues persist:

```bash
cd wizardai_aws_s3_bucket/test
go fmt ./...
```

#### Manual Fix
```bash
# Use the formatting script
./scripts/format-code.sh

# Or format manually
terraform fmt -recursive
cd wizardai_aws_s3_bucket/test && go fmt ./...
```

### 4. **AWS Authentication Issues**

**Error Message:**
```
Error: Could not assume role with OIDC
```

**Solutions:**

#### Check OIDC Setup
1. Verify OIDC provider exists in AWS
2. Check IAM role trust policy
3. Ensure `AWS_OIDC_ROLE` secret is set correctly

#### Verify Permissions
```yaml
permissions:
  id-token: write    # Required for OIDC
  contents: read
```

#### Debug Steps
```bash
# Check role
aws iam get-role --role-name GitHubActions-TerraformS3Module

# Test assume role
aws sts assume-role-with-web-identity \
  --role-arn $AWS_OIDC_ROLE \
  --role-session-name test \
  --web-identity-token $ACTIONS_ID_TOKEN_REQUEST_TOKEN
```

### 5. **Workflow Not Triggering**

**Possible Causes:**
- Workflow file syntax errors
- Incorrect trigger conditions
- Branch protection rules
- Repository permissions

**Solutions:**

#### Check Workflow Syntax
```bash
# Validate YAML syntax
yamllint .github/workflows/*.yml
```

#### Verify Triggers
```yaml
on:
  pull_request:
    branches: [ master, main ]  # Ensure correct branch names
    types: [opened, synchronize, reopened]
```

#### Check Repository Settings
- Actions must be enabled
- Workflow permissions must be set
- Branch protection rules shouldn't block workflows

## 🔧 **Debugging Commands**

### GitHub CLI Commands
```bash
# List workflow runs
gh run list --workflow=ci.yml

# View workflow details
gh run view <run-id>

# View workflow logs
gh run view <run-id> --log

# Re-run failed workflow
gh run rerun <run-id>

# Check repository permissions
gh api repos/:owner/:repo --jq '.permissions'
```

### Local Testing
```bash
# Test Terraform locally
cd wizardai_aws_s3_bucket
terraform init
terraform validate
terraform fmt -check -recursive

# Test Go code locally
cd wizardai_aws_s3_bucket/test
go fmt ./...
go vet ./...
go test -v
```

## 📊 **Workflow Status Indicators**

| Status | Icon | Meaning |
|--------|------|---------|
| Success | ✅ | Job completed successfully |
| Failure | ❌ | Job failed with errors |
| Cancelled | ⏭️ | Job was cancelled |
| Skipped | ⚠️ | Job was skipped due to conditions |
| In Progress | 🔄 | Job is currently running |

## 🛠️ **Quick Fixes**

### Fix All Formatting Issues
```bash
./scripts/format-code.sh
```

### Reset Workflow Permissions
1. Repository Settings → Actions → General
2. Set "Workflow permissions" to "Read and write permissions"
3. Save changes

### Re-run Failed Workflows
```bash
gh run rerun --failed
```

### Check Workflow File Syntax
```bash
# Install yamllint
pip install yamllint

# Check syntax
yamllint .github/workflows/
```

## 📚 **Additional Resources**

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Permissions](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs)
- [Troubleshooting Workflows](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)
- [AWS OIDC Setup Guide](AWS_OIDC_SETUP.md)

## 🆘 **Getting Help**

If you're still experiencing issues:

1. **Check the logs** in GitHub Actions tab
2. **Review permissions** in repository settings
3. **Validate YAML syntax** of workflow files
4. **Test locally** before pushing
5. **Create an issue** with error details and logs

Remember: Most issues are related to permissions or missing setup steps. The workflows are designed to be resilient and provide helpful error messages.