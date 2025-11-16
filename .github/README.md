# CI/CD Pipeline Documentation

This directory contains GitHub Actions workflows for the Wizard.AI AWS S3 Bucket Terraform module.

## Workflows Overview

### 🔄 CI Pipeline (`ci.yml`)
**Triggers:** Pull requests and pushes to master/main branch

**Jobs:**
- **Terraform Validation**: Format check, init, validate, and linting with tflint
- **Security Scan**: Checkov, tfsec security analysis with SARIF upload
- **Documentation Check**: Ensures terraform-docs is up to date
- **Terratest**: Runs comprehensive tests (basic, production, validation)
- **Cost Estimation**: Infracost analysis for PR cost impact

### 🚀 Release Pipeline (`release.yml`)
**Triggers:** Pushes to master/main branch, manual workflow dispatch

**Features:**
- Automatic semantic versioning (patch/minor/major)
- Changelog generation from commit history
- Git tag creation with detailed annotations
- GitHub release creation with module assets
- Slack/Teams notifications

### 🛡️ Security Scan (`security-scan.yml`)
**Triggers:** Daily schedule (2 AM UTC), pushes, PRs, manual dispatch

**Security Tools:**
- **Checkov**: Infrastructure as Code security scanner
- **tfsec**: Terraform-specific security scanner
- **Terrascan**: Multi-cloud security scanner
- **Semgrep**: Static analysis security scanner
- **Govulncheck**: Go vulnerability scanner
- **Nancy**: Dependency vulnerability scanner
- **Gosec**: Go security checker
- **Regula**: OPA-based compliance checker

### ✅ PR Validation (`pr-validation.yml`)
**Triggers:** Pull request events (opened, synchronize, reopened, ready_for_review)

**Validation Checks:**
- PR title format (conventional commits)
- Breaking changes detection
- File structure validation
- Commit message validation
- Terraform plan generation and PR comments
- Code quality checks (fmt, vet, staticcheck)
- Documentation completeness
- PR size analysis

### 📦 Dependency Updates (`dependency-update.yml`)
**Triggers:** Weekly schedule (Mondays 10 AM UTC), manual dispatch

**Features:**
- Terraform provider version checks
- Go module updates with `go get -u`
- Security vulnerability scanning
- Automated PR creation for updates

## Required Secrets

Configure these secrets in your GitHub repository settings:

### AWS OIDC Role (for testing)
```
AWS_OIDC_ROLE=arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-TerraformS3Module
```

> **Note**: The pipeline now uses OIDC for AWS authentication instead of long-lived access keys. See [AWS_OIDC_SETUP.md](../AWS_OIDC_SETUP.md) for detailed setup instructions.

### Optional Integrations
```
INFRACOST_API_KEY=your_infracost_key          # For cost estimation
SLACK_WEBHOOK_URL=your_slack_webhook          # For release notifications
TEAMS_WEBHOOK_URL=your_teams_webhook          # For release notifications
```

## Workflow Features

### 🔒 Security Features
- SARIF upload to GitHub Security tab
- Multiple security scanners for comprehensive coverage
- Dependency vulnerability scanning
- Compliance checking against AWS Config rules
- Security summary reports

### 📊 Quality Assurance
- Terraform formatting and validation
- Go code quality checks
- Documentation completeness validation
- Breaking change detection
- PR size analysis

### 🚀 Automation
- Automatic semantic versioning
- Changelog generation
- Release asset creation
- Dependency updates
- Cost impact analysis

### 📈 Monitoring
- Daily security scans
- Weekly dependency updates
- Comprehensive test coverage
- Performance monitoring

## Best Practices Implemented

### 1. Security First
- Multiple security scanners
- SARIF integration with GitHub Security
- Secrets scanning
- Dependency vulnerability checks

### 2. Quality Gates
- All PRs must pass validation
- Breaking change detection
- Code formatting enforcement
- Documentation requirements

### 3. Automation
- Semantic versioning
- Automated releases
- Dependency management
- Cost monitoring

### 4. Observability
- Detailed logging
- Artifact uploads
- Security reports
- Performance metrics

## Usage Examples

### Manual Release
```bash
# Trigger a manual release with version bump
gh workflow run release.yml -f version_type=minor
```

### Security Scan
```bash
# Run security scan manually
gh workflow run security-scan.yml
```

### Dependency Updates
```bash
# Trigger dependency update check
gh workflow run dependency-update.yml
```

## Customization

### Adding New Security Scanners
1. Add scanner step to `security-scan.yml`
2. Configure SARIF upload if supported
3. Update security summary job

### Modifying Release Process
1. Edit version calculation logic in `release.yml`
2. Customize changelog format
3. Add additional notification channels

### Extending PR Validation
1. Add new validation jobs to `pr-validation.yml`
2. Update PR summary generation
3. Configure additional quality checks

## Troubleshooting

### Common Issues

**Tests failing in CI but passing locally:**
- Check AWS credentials configuration
- Verify Terraform version consistency
- Ensure clean state between test runs

**Security scans reporting false positives:**
- Configure scanner-specific ignore files
- Update security policies
- Review and whitelist known safe patterns

**Release workflow not triggering:**
- Verify branch protection rules
- Check workflow permissions
- Ensure proper commit message format

### Debug Commands

```bash
# Check workflow status
gh run list --workflow=ci.yml

# View workflow logs
gh run view <run-id> --log

# Re-run failed workflow
gh run rerun <run-id>
```

## Contributing

When contributing to the CI/CD pipeline:

1. Test changes in a fork first
2. Update documentation for new features
3. Follow conventional commit format
4. Ensure backward compatibility
5. Add appropriate tests

## Support

For issues with the CI/CD pipeline:
1. Check the workflow logs
2. Review this documentation
3. Create an issue with the `ci` label
4. Include relevant error messages and context