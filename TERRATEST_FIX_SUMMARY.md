# Terratest CI/CD Fix Summary

## Issues Identified

The CI pipeline had multiple issues:

1. **Workflow Syntax Error**: `secrets` context cannot be used in job-level `if` conditions
2. **Limited Error Output**: Only showing last 50 lines of test output wasn't enough to diagnose issues
3. **No Real-time Output**: Tests were redirected to file without showing progress
4. **Missing Exit Code**: Error messages didn't include the actual exit code from failed tests
5. **Pipeline Error Handling**: Missing `pipefail` option could mask test failures in pipes

## Fixes Applied

### 1. Fixed Workflow Syntax Errors

#### Issue 1: Invalid secrets reference in job-level if
The cost-estimation job had an invalid condition:
```yaml
# BEFORE (Invalid - secrets not available in job-level if)
if: github.event_name == 'pull_request' && secrets.INFRACOST_API_KEY != ''
```

Changed to:
```yaml
# AFTER (Valid - check secret in first step)
if: github.event_name == 'pull_request'
steps:
  - name: Check if Infracost is configured
    id: check_infracost
    run: |
      if [ -n "${{ secrets.INFRACOST_API_KEY }}" ]; then
        echo "enabled=true" >> $GITHUB_OUTPUT
      else
        echo "enabled=false" >> $GITHUB_OUTPUT
      fi
  
  # All subsequent steps check: if: steps.check_infracost.outputs.enabled == 'true'
```

This allows the job to run but skip steps when Infracost is not configured.

#### Issue 2: Working directory before checkout
The job had a default working directory set, but the first step tried to run before checkout:
```yaml
# BEFORE (Invalid - working directory doesn't exist yet)
defaults:
  run:
    working-directory: ./wizardai_aws_s3_bucket/examples/basic
steps:
  - name: Check if Infracost is configured
    run: ...  # Fails - directory doesn't exist
  - name: Checkout code
    uses: actions/checkout@v4
```

Changed to:
```yaml
# AFTER (Valid - checkout first, then set working directory per step)
steps:
  - name: Checkout code
    uses: actions/checkout@v4
  
  - name: Check if Infracost is configured
    run: ...  # Works - no working directory needed
  
  - name: Terraform Init
    working-directory: ./wizardai_aws_s3_bucket/examples/basic
    run: terraform init
```

### 2. Improved Error Visibility
- Changed from redirecting output (`>`) to using `tee` command for real-time output
- Increased error output from 50 to 200 lines in test failure reports
- Added exit code capture and display in error messages

### 3. Better Output Handling and Error Propagation
Changed from:
```bash
make test-basic > output.txt 2>&1
```

To:
```bash
set -o pipefail
make test-basic 2>&1 | tee output.txt
```

This allows:
- Real-time test output in GitHub Actions logs
- Full output saved to file for artifacts
- Proper error propagation through pipes
- Better debugging experience

**Applied `set -o pipefail` to all pipeline steps:**
- ✅ Terraform Format Check
- ✅ Terraform Init
- ✅ Terraform Validate
- ✅ TFLint Analysis
- ✅ Documentation Check
- ✅ Terraform Plan
- ✅ Terratest (all test suites)
- ✅ Infracost breakdown

This ensures that any command failure in a pipe will cause the entire step to fail, preventing silent errors.

### 4. Enhanced Error Messages
Now includes:
- Exit code from failed tests
- Last 200 lines of output (up from 50)
- Clear indication of which test suite failed

### 5. Environment Verification
Added a verification step before tests run to check:
- Go version (should be 1.24.0)
- Terraform version (should be 1.6.0)
- AWS CLI version
- AWS credentials status (via `aws sts get-caller-identity`)
- Current working directory

This helps quickly identify environment issues before tests execute.

### 6. TFLint Cache Clearing
Added a cache clearing step before TFLint initialization:
```yaml
- name: Clear TFLint cache
  run: |
    echo "🧹 Clearing TFLint cache..."
    rm -rf .tflint.d/ || true
    echo "✅ Cache cleared"
```

This ensures:
- Fresh analysis on every run
- No stale warnings from previous runs
- Accurate detection of unused variables and other issues

## Test Matrix

The Terratest job runs three test suites in parallel:
- **basic**: Tests basic S3 bucket functionality with default encryption
- **production**: Tests production configuration with KMS encryption and lifecycle policies
- **validation**: Tests input validation and HTTPS enforcement

## Next Steps

1. Commit these changes to your branch
2. Push to trigger the CI pipeline
3. Check the "Verify environment" step output to confirm:
   - Go 1.24.0 is installed
   - AWS credentials are working
   - All tools are available
4. Review the real-time test output in GitHub Actions logs
5. If tests fail, check the PR comment for the last 200 lines of error output

## Debugging Tips

If tests continue to fail:

1. **Check AWS Credentials**: Look at the "Verify environment" step - `aws sts get-caller-identity` should show your assumed role
2. **Check Test Output**: Full output is now visible in real-time in the GitHub Actions logs
3. **Download Artifacts**: Test output files are uploaded as artifacts for detailed analysis
4. **Review Exit Codes**: Error messages now include the actual exit code from failed tests

## Common Issues

### AWS Authentication Failures
- Verify `AWS_OIDC_ROLE` secret is set correctly
- Check IAM role trust policy allows GitHub OIDC
- Ensure role has necessary S3 and KMS permissions

### Go Module Issues
- Verify Go 1.24.0 is being used (check "Verify environment" step)
- Check if `go.mod` dependencies are compatible
- Look for module download errors in test output

### Terraform Issues
- Ensure Terraform 1.6.0 is installed
- Check if examples have valid configuration
- Verify AWS provider version compatibility
