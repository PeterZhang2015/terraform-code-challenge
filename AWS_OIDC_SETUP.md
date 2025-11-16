# AWS OIDC Setup for GitHub Actions

## 🎯 Overview

The CI/CD pipeline now uses OpenID Connect (OIDC) for AWS authentication instead of long-lived access keys. This provides enhanced security through temporary credentials and eliminates the need to store AWS access keys as GitHub secrets.

## 🔒 Security Benefits

### OIDC vs Access Keys
| Feature | Long-lived Access Keys | OIDC |
|---------|----------------------|------|
| **Security** | ❌ Permanent credentials | ✅ Temporary credentials |
| **Rotation** | ❌ Manual rotation required | ✅ Automatic rotation |
| **Scope** | ❌ Broad permissions | ✅ Fine-grained permissions |
| **Audit** | ❌ Limited traceability | ✅ Detailed audit trail |
| **Compromise Risk** | ❌ High (permanent access) | ✅ Low (time-limited) |

### Key Advantages
- **No stored secrets**: No AWS access keys in GitHub secrets
- **Temporary credentials**: Each workflow run gets fresh, time-limited credentials
- **Fine-grained permissions**: IAM roles can be scoped to specific repositories and branches
- **Audit trail**: CloudTrail logs show exactly which GitHub Actions assumed roles
- **Automatic rotation**: Credentials expire automatically

## ⚙️ AWS Setup

### 1. Create OIDC Identity Provider

```bash
# Create the OIDC identity provider
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

### 2. Create IAM Role for GitHub Actions

Create a trust policy file (`github-actions-trust-policy.json`):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:YOUR_GITHUB_ORG/YOUR_REPO_NAME:ref:refs/heads/master",
                        "repo:YOUR_GITHUB_ORG/YOUR_REPO_NAME:ref:refs/heads/main",
                        "repo:YOUR_GITHUB_ORG/YOUR_REPO_NAME:pull_request"
                    ]
                }
            }
        }
    ]
}
```

Create the IAM role:

```bash
# Create the role
aws iam create-role \
    --role-name GitHubActions-TerraformS3Module \
    --assume-role-policy-document file://github-actions-trust-policy.json \
    --description "Role for GitHub Actions to run Terraform tests"
```

### 3. Create IAM Policy for S3 Testing

Create a permissions policy file (`s3-testing-policy.json`):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:GetBucketEncryption",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketPolicy",
                "s3:GetBucketLifecycleConfiguration",
                "s3:PutBucketVersioning",
                "s3:PutBucketEncryption",
                "s3:PutBucketPublicAccessBlock",
                "s3:PutBucketPolicy",
                "s3:PutBucketLifecycleConfiguration",
                "s3:ListBucket",
                "s3:HeadBucket"
            ],
            "Resource": [
                "arn:aws:s3:::wizardai-pr-test-*",
                "arn:aws:s3:::wizardai-test-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:CreateKey",
                "kms:DescribeKey",
                "kms:GetKeyPolicy",
                "kms:ListKeys",
                "kms:ListAliases",
                "kms:TagResource",
                "kms:ScheduleKeyDeletion"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:KeySpec": "SYMMETRIC_DEFAULT",
                    "kms:KeyUsage": "ENCRYPT_DECRYPT"
                }
            }
        }
    ]
}
```

Attach the policy to the role:

```bash
# Create the policy
aws iam create-policy \
    --policy-name GitHubActions-S3Testing \
    --policy-document file://s3-testing-policy.json \
    --description "Permissions for GitHub Actions to test S3 module"

# Attach the policy to the role
aws iam attach-role-policy \
    --role-name GitHubActions-TerraformS3Module \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActions-S3Testing
```

### 4. Configure GitHub Secret

Add the following secret to your GitHub repository:

```
AWS_OIDC_ROLE=arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-TerraformS3Module
```

## 🔧 Workflow Configuration

### Required Permissions

Each job that needs AWS access must include:

```yaml
permissions:
  id-token: write    # Required for OIDC token
  contents: read     # Required for repository access
```

### AWS Authentication Step

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_OIDC_ROLE }}
    role-session-name: GitHubActions-JobName-${{ github.run_id }}
    aws-region: us-west-2
```

### Session Naming Convention

Each workflow job uses a unique session name for better audit trails:

- **Terratest**: `GitHubActions-Terratest-{run_id}-{test_type}`
- **Terraform Plan**: `GitHubActions-TerraformPlan-{run_id}`
- **Cost Estimation**: `GitHubActions-CostEstimation-{run_id}`
- **PR Validation**: `GitHubActions-PRValidation-{run_id}`

## 🛡️ Security Best Practices

### 1. Principle of Least Privilege

The IAM role only has permissions for:
- Creating/managing test S3 buckets with specific naming patterns
- KMS operations for encryption testing
- No access to production resources

### 2. Repository and Branch Restrictions

The trust policy restricts access to:
- Specific repository: `repo:YOUR_ORG/YOUR_REPO`
- Specific branches: `master`, `main`
- Pull request events: `pull_request`

### 3. Resource Naming Patterns

S3 bucket permissions are restricted to test patterns:
- `wizardai-pr-test-*` (for PR testing)
- `wizardai-test-*` (for general testing)

### 4. Time-Limited Access

- Credentials automatically expire (typically 1 hour)
- Each workflow run gets fresh credentials
- No persistent access tokens

## 📊 Monitoring and Auditing

### CloudTrail Events

Monitor these CloudTrail events for OIDC usage:

```json
{
    "eventName": "AssumeRoleWithWebIdentity",
    "sourceIPAddress": "github-actions-runner-ip",
    "userIdentity": {
        "type": "WebIdentityUser",
        "principalId": "arn:aws:sts::ACCOUNT:assumed-role/GitHubActions-TerraformS3Module/GitHubActions-Terratest-123456",
        "arn": "arn:aws:sts::ACCOUNT:assumed-role/GitHubActions-TerraformS3Module/GitHubActions-Terratest-123456",
        "accountId": "ACCOUNT"
    }
}
```

### CloudWatch Metrics

Create CloudWatch alarms for:
- Failed assume role attempts
- Unusual API call patterns
- Resource creation outside expected patterns

## 🚨 Troubleshooting

### Common Issues

**1. "No OpenIDConnect provider found"**
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers
```

**2. "Not authorized to perform sts:AssumeRoleWithWebIdentity"**
- Check trust policy conditions
- Verify repository name and branch in trust policy
- Ensure `id-token: write` permission is set

**3. "Access denied" for AWS resources**
- Check IAM policy permissions
- Verify resource naming patterns
- Review CloudTrail logs for specific denied actions

### Debug Commands

```bash
# Check role trust policy
aws iam get-role --role-name GitHubActions-TerraformS3Module

# List attached policies
aws iam list-attached-role-policies --role-name GitHubActions-TerraformS3Module

# Get policy details
aws iam get-policy-version --policy-arn POLICY_ARN --version-id v1
```

### GitHub Actions Debug

Enable debug logging in workflows:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## 🔄 Migration from Access Keys

### Before Migration

1. **Backup current setup**: Document existing access key permissions
2. **Test OIDC setup**: Create OIDC role in test environment first
3. **Verify permissions**: Ensure OIDC role has equivalent permissions

### Migration Steps

1. **Create OIDC provider and role** (as described above)
2. **Update workflows** to use OIDC authentication
3. **Test thoroughly** with pull requests
4. **Remove old secrets** after successful testing
5. **Deactivate old access keys** in AWS

### Rollback Plan

Keep old access keys temporarily:
1. Revert workflow changes
2. Re-add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets
3. Test workflows
4. Investigate OIDC issues

## 📚 Additional Resources

- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS Configure Credentials Action](https://github.com/aws-actions/configure-aws-credentials)
- [Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## 🎉 Benefits Summary

After implementing OIDC:

✅ **Enhanced Security**: No long-lived credentials stored in GitHub
✅ **Better Audit Trail**: Clear tracking of which workflows accessed AWS
✅ **Automatic Rotation**: Credentials expire automatically
✅ **Fine-grained Access**: Permissions scoped to specific repositories and branches
✅ **Reduced Risk**: Compromised credentials have limited time window
✅ **Compliance**: Meets security best practices for CI/CD pipelines

The OIDC setup provides a more secure, auditable, and maintainable approach to AWS authentication in GitHub Actions workflows.