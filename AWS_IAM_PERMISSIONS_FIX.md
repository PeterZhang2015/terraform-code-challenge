# AWS IAM Permissions Fix for Terratest

## Issue Identified

The production test is failing because the IAM role `terraform-s3-role` lacks KMS permissions:

```
Error: creating KMS Key: operation error KMS: CreateKey, https response error StatusCode: 400, 
RequestID: c533d3bb-1cc9-4388-a430-33236528c72f, api error AccessDeniedException: 
User: arn:aws:sts::643058308141:assumed-role/terraform-s3-role/GitHubActions-Terratest-19807773950-production 
is not authorized to perform: kms:TagResource because no identity-based policy allows the kms:TagResource action
```

## Root Cause

The production test creates a KMS key for S3 bucket encryption, but the IAM role only has S3 permissions. It needs additional KMS permissions to:
1. Create KMS keys
2. Tag KMS keys
3. Create KMS aliases
4. Enable key rotation
5. Use keys for encryption/decryption

## Required KMS Permissions

Add the following permissions to the `terraform-s3-role` IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KMSKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:DisableKeyRotation",
        "kms:GetKeyRotationStatus",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSKeyUsage",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSAliasManagement",
      "Effect": "Allow",
      "Action": [
        "kms:ListAliases"
      ],
      "Resource": "*"
    }
  ]
}
```

## How to Apply the Fix

### Option 1: Using AWS Console

1. Go to AWS IAM Console
2. Navigate to Roles → `terraform-s3-role`
3. Click "Add permissions" → "Create inline policy"
4. Switch to JSON tab
5. Paste the policy above
6. Name it `KMSManagementPolicy`
7. Click "Create policy"

### Option 2: Using AWS CLI

```bash
# Save the policy to a file
cat > kms-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KMSKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:DisableKeyRotation",
        "kms:GetKeyRotationStatus",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSKeyUsage",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSAliasManagement",
      "Effect": "Allow",
      "Action": [
        "kms:ListAliases"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Apply the policy
aws iam put-role-policy \
  --role-name terraform-s3-role \
  --policy-name KMSManagementPolicy \
  --policy-document file://kms-policy.json
```

### Option 3: Using Terraform

If you manage your IAM roles with Terraform, add this policy:

```hcl
resource "aws_iam_role_policy" "kms_management" {
  name = "KMSManagementPolicy"
  role = aws_iam_role.terraform_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KMSKeyManagement"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:DescribeKey",
          "kms:EnableKeyRotation",
          "kms:DisableKeyRotation",
          "kms:GetKeyRotationStatus",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ListResourceTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSKeyUsage"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSAliasManagement"
        Effect = "Allow"
        Action = [
          "kms:ListAliases"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Verification

After applying the policy, verify the permissions:

```bash
# Check the role's policies
aws iam list-role-policies --role-name terraform-s3-role

# Get the policy document
aws iam get-role-policy \
  --role-name terraform-s3-role \
  --policy-name KMSManagementPolicy
```

## Re-run the Tests

Once the permissions are added:

1. Push a new commit or re-run the workflow
2. The production test should now pass
3. Verify in the logs that the KMS key is created successfully

## Security Considerations

### Least Privilege Approach

If you want to restrict KMS permissions further, you can:

1. **Limit to specific regions:**
   ```json
   "Resource": "arn:aws:kms:us-west-2:643058308141:key/*"
   ```

2. **Add conditions for tagging:**
   ```json
   "Condition": {
     "StringEquals": {
       "aws:RequestedRegion": "us-west-2"
     }
   }
   ```

3. **Limit key usage to S3:**
   ```json
   "Condition": {
     "StringEquals": {
       "kms:ViaService": "s3.us-west-2.amazonaws.com"
     }
   }
   ```

### Recommended Production Policy

For production use, consider this more restrictive policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KMSKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:GetKeyRotationStatus",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-west-2"
        }
      }
    },
    {
      "Sid": "KMSKeyUsageForS3",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.us-west-2.amazonaws.com"
        }
      }
    }
  ]
}
```

## Next Steps

1. **Apply the KMS permissions** to the IAM role
2. **Re-run the CI pipeline** to verify the fix
3. **Monitor the test results** - all three test suites should now pass
4. **Consider updating** the AWS_OIDC_SETUP.md documentation to include KMS permissions

## Related Documentation

- [AWS KMS Permissions Reference](https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html)
- [S3 Bucket Keys with KMS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
