# Terratest Debugging Guide

## Current Status

The Terratest production test is now running but failing. The good news:
- ✅ Infrastructure is being created successfully
- ✅ Infrastructure is being destroyed successfully  
- ✅ Test output is now visible in GitHub Actions logs
- ❌ One or more assertions are failing

## Recent Improvements

### 1. Enhanced Test Assertions
Added better error messages and nil checks to the production test:
```go
// Before
assert.Equal(t, expectedBucketName, bucketID)

// After
assert.Equal(t, expectedBucketName, bucketID, "Bucket name should follow naming convention")
```

### 2. Added Debug Logging
The test now logs key values:
```go
t.Logf("Bucket ID: %s", bucketID)
t.Logf("Bucket ARN: %s", bucketARN)
t.Logf("KMS Key ID: %s", kmsKeyID)
```

### 3. Improved Nil Checks
The KMS encryption check now has proper nil handling:
```go
if len(rules) > 0 && rules[0].ApplyServerSideEncryptionByDefault != nil {
    assert.Equal(t, types.ServerSideEncryptionAwsKms, ...)
    assert.NotNil(t, rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID, ...)
} else {
    t.Fatal("Encryption rule or default encryption not configured properly")
}
```

## What to Look For in Next Test Run

When you run the tests again, look for these in the GitHub Actions logs:

### 1. Debug Output
```
TestS3BucketProduction 2025-12-01T... logger.go:67: Bucket ID: wizardai-test-prod-xxx-production
TestS3BucketProduction 2025-12-01T... logger.go:67: Bucket ARN: arn:aws:s3:::wizardai-test-prod-xxx-production
TestS3BucketProduction 2025-12-01T... logger.go:67: KMS Key ID: arn:aws:kms:us-west-2:...
```

### 2. Assertion Failures
Look for lines like:
```
TestS3BucketProduction 2025-12-01T... logger.go:67:     Error: Not equal:
TestS3BucketProduction 2025-12-01T... logger.go:67:             expected: "..."
TestS3BucketProduction 2025-12-01T... logger.go:67:             actual  : "..."
TestS3BucketProduction 2025-12-01T... logger.go:67:     Messages: Bucket name should follow naming convention
```

### 3. Specific Error Messages
The test now includes descriptive messages for each assertion:
- "Bucket name should follow naming convention"
- "Bucket ARN should match expected format"
- "KMS key ID should not be empty"
- "Failed to get bucket encryption"
- "Encryption configuration should not be nil"
- "Encryption rules should not be empty"
- "Should use KMS encryption"
- "KMS key ID should be set"
- "Encryption rule or default encryption not configured properly"

## Common Issues and Solutions

### Issue 1: Bucket Name Mismatch
**Symptom**: "Bucket name should follow naming convention" error
**Cause**: The module might be adding/removing prefixes
**Solution**: Check the module's `main.tf` to see how it constructs the bucket name

### Issue 2: KMS Key Not Found
**Symptom**: "KMS key ID should not be empty" error
**Cause**: The KMS key output might not be configured correctly
**Solution**: Verify `examples/production/outputs.tf` and ensure the KMS key is created

### Issue 3: Encryption Not Configured
**Symptom**: "Encryption rule or default encryption not configured properly" error
**Cause**: The bucket encryption might not be using KMS
**Solution**: Check the module's encryption configuration in `main.tf`

### Issue 4: Lifecycle Rules Missing
**Symptom**: Error about lifecycle rules being empty
**Cause**: Lifecycle rules might not be applied correctly
**Solution**: Verify the `lifecycle_rules` variable is passed correctly in `examples/production/main.tf`

## Next Steps

1. **Commit and push** the test improvements:
   ```bash
   git add wizardai_aws_s3_bucket/test/s3_bucket_test.go
   git commit -m "test: add debug logging and better error messages to production test"
   git push
   ```

2. **Review the test output** in GitHub Actions - you should now see:
   - The actual values being tested (Bucket ID, ARN, KMS Key)
   - Clear error messages indicating which assertion failed
   - The expected vs actual values for failed assertions

3. **Fix the root cause** based on the error messages

4. **Verify locally** (optional):
   ```bash
   cd wizardai_aws_s3_bucket/test
   go test -v -run TestS3BucketProduction -timeout 30m
   ```

## Test Structure

The production test validates:
1. ✅ Bucket name follows naming convention
2. ✅ Bucket ARN is correctly formatted
3. ✅ KMS key is created and output
4. ✅ Bucket exists and is accessible
5. ✅ KMS encryption is enabled (not AES256)
6. ✅ KMS key ID is set in encryption config
7. ✅ Lifecycle rules are configured

Each step now has descriptive error messages to help identify failures quickly.
