package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestS3BucketBasic tests the basic functionality of the S3 bucket module
func TestS3BucketBasic(t *testing.T) {
	t.Parallel()

	// Generate a random bucket name to avoid conflicts
	uniqueID := random.UniqueId()
	bucketName := fmt.Sprintf("test-bucket-%s", strings.ToLower(uniqueID))
	
	// AWS region for testing
	awsRegion := "us-west-2"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"aws_region":   awsRegion,
			"bucket_name":  bucketName,
			"environment":  "development",
			"tags": map[string]string{
				"Test": "terratest",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	bucketID := terraform.Output(t, terraformOptions, "bucket_name")
	bucketARN := terraform.Output(t, terraformOptions, "bucket_arn")

	// Verify bucket name follows naming convention
	expectedBucketName := fmt.Sprintf("wizardai-%s-development", bucketName)
	assert.Equal(t, expectedBucketName, bucketID)

	// Verify bucket ARN format
	expectedARNPrefix := fmt.Sprintf("arn:aws:s3:::wizardai-%s-development", bucketName)
	assert.Equal(t, expectedARNPrefix, bucketARN)

	// Create AWS session to verify bucket properties
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	require.NoError(t, err)

	s3Client := s3.New(sess)

	// Test bucket exists and is accessible
	_, err = s3Client.HeadBucket(&s3.HeadBucketInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)

	// Test encryption is enabled
	encryptionResult, err := s3Client.GetBucketEncryption(&s3.GetBucketEncryptionInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
	assert.NotNil(t, encryptionResult.ServerSideEncryptionConfiguration)
	assert.NotEmpty(t, encryptionResult.ServerSideEncryptionConfiguration.Rules)

	// Test versioning is enabled
	versioningResult, err := s3Client.GetBucketVersioning(&s3.GetBucketVersioningInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
	assert.Equal(t, "Enabled", *versioningResult.Status)

	// Test public access is blocked
	publicAccessResult, err := s3Client.GetPublicAccessBlock(&s3.GetPublicAccessBlockInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
	assert.True(t, *publicAccessResult.PublicAccessBlockConfiguration.BlockPublicAcls)
	assert.True(t, *publicAccessResult.PublicAccessBlockConfiguration.BlockPublicPolicy)
	assert.True(t, *publicAccessResult.PublicAccessBlockConfiguration.IgnorePublicAcls)
	assert.True(t, *publicAccessResult.PublicAccessBlockConfiguration.RestrictPublicBuckets)

	// Test bucket policy exists (HTTPS enforcement)
	_, err = s3Client.GetBucketPolicy(&s3.GetBucketPolicyInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
}

// TestS3BucketProduction tests the production configuration with KMS encryption
func TestS3BucketProduction(t *testing.T) {
	t.Parallel()

	// Generate a random bucket name to avoid conflicts
	uniqueID := random.UniqueId()
	bucketName := fmt.Sprintf("test-prod-%s", strings.ToLower(uniqueID))
	
	// AWS region for testing
	awsRegion := "us-west-2"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/production",
		Vars: map[string]interface{}{
			"aws_region":   awsRegion,
			"bucket_name":  bucketName,
			"environment":  "production",
			"tags": map[string]string{
				"Test":        "terratest",
				"Environment": "production",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	bucketID := terraform.Output(t, terraformOptions, "bucket_name")
	bucketARN := terraform.Output(t, terraformOptions, "bucket_arn")
	kmsKeyID := terraform.Output(t, terraformOptions, "kms_key_id")

	// Verify bucket name follows naming convention
	expectedBucketName := fmt.Sprintf("wizardai-%s-production", bucketName)
	assert.Equal(t, expectedBucketName, bucketID)

	// Verify bucket ARN format
	expectedARNPrefix := fmt.Sprintf("arn:aws:s3:::wizardai-%s-production", bucketName)
	assert.Equal(t, expectedARNPrefix, bucketARN)

	// Verify KMS key was created
	assert.NotEmpty(t, kmsKeyID)

	// Create AWS session to verify bucket properties
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	require.NoError(t, err)

	s3Client := s3.New(sess)

	// Test KMS encryption is enabled
	encryptionResult, err := s3Client.GetBucketEncryption(&s3.GetBucketEncryptionInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
	assert.NotNil(t, encryptionResult.ServerSideEncryptionConfiguration)
	rules := encryptionResult.ServerSideEncryptionConfiguration.Rules
	assert.NotEmpty(t, rules)
	assert.Equal(t, "aws:kms", *rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm)
	assert.NotNil(t, rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID)

	// Test lifecycle configuration exists
	lifecycleResult, err := s3Client.GetBucketLifecycleConfiguration(&s3.GetBucketLifecycleConfigurationInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
	assert.NotEmpty(t, lifecycleResult.Rules)
}


// TestS3BucketInvalidEnvironment tests validation of environment parameter
func TestS3BucketInvalidEnvironment(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	bucketName := fmt.Sprintf("test-invalid-%s", strings.ToLower(uniqueID))
	awsRegion := "us-west-2"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"aws_region":   awsRegion,
			"bucket_name":  bucketName,
			"environment":  "invalid-env", // This should fail validation
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// This should fail during plan phase due to validation
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "Environment must be one of: development, staging, production")
}

// TestS3BucketHTTPSEnforcement tests that HTTP requests are denied
func TestS3BucketHTTPSEnforcement(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	bucketName := fmt.Sprintf("test-https-%s", strings.ToLower(uniqueID))
	awsRegion := "us-west-2"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"aws_region":   awsRegion,
			"bucket_name":  bucketName,
			"environment":  "development",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_name")

	// Create AWS session
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	require.NoError(t, err)

	s3Client := s3.New(sess)

	// Test that bucket policy exists and contains HTTPS enforcement
	policyResult, err := s3Client.GetBucketPolicy(&s3.GetBucketPolicyInput{
		Bucket: aws.String(bucketID),
	})
	require.NoError(t, err)
	
	policy := *policyResult.Policy
	assert.Contains(t, policy, "DenyInsecureConnections")
	assert.Contains(t, policy, "aws:SecureTransport")
	assert.Contains(t, policy, "false")
}