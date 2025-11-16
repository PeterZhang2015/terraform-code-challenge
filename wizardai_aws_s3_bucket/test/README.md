# Terratest Test Suite

This directory contains comprehensive tests for the Wizard.AI S3 Bucket Terraform module using [Terratest](https://terratest.gruntwork.io/).

## Prerequisites

- Go 1.21 or later
- AWS CLI configured with appropriate credentials
- Terraform installed
- AWS account with permissions to create S3 buckets, KMS keys, and IAM policies

## Test Structure

### Test Files

- `s3_bucket_test.go` - Main test suite with comprehensive test cases
- `go.mod` - Go module dependencies
- `Makefile` - Test automation and convenience commands
- `README.md` - This documentation

### Test Cases

1. **TestS3BucketBasic** - Tests basic functionality:
   - Bucket creation with correct naming convention
   - Default AES256 encryption
   - Versioning enabled
   - Public access blocked
   - HTTPS enforcement policy

2. **TestS3BucketProduction** - Tests production environment:
   - KMS encryption with customer-managed keys
   - Advanced lifecycle rules
   - Production-grade security settings

3. **TestS3BucketInvalidEnvironment** - Tests input validation:
   - Validates environment parameter constraints
   - Ensures proper error handling

4. **TestS3BucketHTTPSEnforcement** - Tests security policies:
   - Verifies HTTPS-only access enforcement
   - Validates bucket policy configuration

## Running Tests

### Prerequisites Setup

```bash
# Install dependencies
make deps

# Ensure AWS credentials are configured
aws configure list
```

### Run All Tests

```bash
# Run all tests sequentially
make test

```

### Run Individual Test Suites

```bash
# Test basic/development environment
make test-basic

# Test production environment
make test-production

# Test validation logic
make test-validation
```

### Run with Coverage

```bash
make test-coverage
```

This generates `coverage.html` with detailed coverage report.

## Test Configuration

### Environment Variables

Tests use the following environment variables:

- `AWS_DEFAULT_REGION` - AWS region for testing (default: us-west-2)
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_SESSION_TOKEN` - AWS session token (if using temporary credentials)

### Test Timeouts

- Basic tests: 30 minutes
- Production tests: 30 minutes (includes KMS key creation)
- Validation tests: 10 minutes
- Parallel execution: 45 minutes total

## What Tests Verify

### Security Compliance

- ✅ Encryption at rest (AES256 or KMS)
- ✅ Encryption in transit (HTTPS-only policy)
- ✅ Public access blocked
- ✅ Proper IAM policies

### Organizational Policies

- ✅ Naming convention: `wizardai-<name>-<environment>`
- ✅ Environment validation (development/staging/production)
- ✅ Required tagging

### Operational Features

- ✅ Versioning configuration
- ✅ Lifecycle rules
- ✅ KMS key management
- ✅ Proper outputs

### Error Handling

- ✅ Invalid environment values
- ✅ Malformed bucket names
- ✅ Missing required parameters

## Cleanup

Tests automatically clean up resources using Terraform destroy in defer statements. If tests fail unexpectedly, you may need to manually clean up:

```bash
# Clean test artifacts
make clean

# Manual cleanup if needed
aws s3 ls | grep "wizardai-test-"
aws s3 rb s3://bucket-name --force
```

## Troubleshooting

### Common Issues

1. **AWS Credentials**: Ensure AWS credentials are properly configured
2. **Permissions**: Tests require permissions to create S3 buckets, KMS keys, and IAM policies
3. **Region**: Some tests are region-specific (us-west-2 by default)
4. **Timeouts**: Increase timeout values for slower AWS regions

### Debug Mode

Run tests with verbose output:

```bash
go test -v -timeout 30m
```

### Test Specific Functions

```bash
go test -v -run TestS3BucketBasic
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Terratest
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - name: Run tests
        run: |
          cd wizardai_aws_s3_bucket/test
          make test
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Contributing

When adding new tests:

1. Follow existing naming conventions
2. Use `t.Parallel()` for independent tests
3. Always use `defer terraform.Destroy(t, terraformOptions)`
4. Add appropriate assertions for new functionality
5. Update this README with new test descriptions