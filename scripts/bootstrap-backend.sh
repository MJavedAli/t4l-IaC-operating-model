#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:=ap-northeast-1}"
: "${STATE_BUCKET:?Set STATE_BUCKET to a globally unique S3 bucket name}"
: "${LOCK_TABLE:?Set LOCK_TABLE to the transitional DynamoDB lock-table name}"
: "${KMS_KEY_ARN:?Set KMS_KEY_ARN to a customer-managed KMS key ARN}"

account_id="$(aws sts get-caller-identity --query Account --output text)"
echo "Bootstrapping Terraform backend in account ${account_id}, region ${AWS_REGION}"

echo "Creating S3 bucket ${STATE_BUCKET}"
if [[ "${AWS_REGION}" == "us-east-1" ]]; then
  aws s3api create-bucket --bucket "${STATE_BUCKET}" --region "${AWS_REGION}"
else
  aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration "LocationConstraint=${AWS_REGION}"
fi

aws s3api put-public-access-block \
  --bucket "${STATE_BUCKET}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-versioning \
  --bucket "${STATE_BUCKET}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${STATE_BUCKET}" \
  --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"aws:kms\",\"KMSMasterKeyID\":\"${KMS_KEY_ARN}\"},\"BucketKeyEnabled\":true}]}"

aws s3api put-bucket-tagging \
  --bucket "${STATE_BUCKET}" \
  --tagging 'TagSet=[{Key=ManagedBy,Value=Bootstrap},{Key=Service,Value=terraform-state},{Key=Environment,Value=prod},{Key=Owner,Value=cloud-infra}]'

echo "Creating transitional DynamoDB lock table ${LOCK_TABLE}"
aws dynamodb create-table \
  --region "${AWS_REGION}" \
  --table-name "${LOCK_TABLE}" \
  --billing-mode PAY_PER_REQUEST \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH

aws dynamodb wait table-exists --region "${AWS_REGION}" --table-name "${LOCK_TABLE}"
aws dynamodb update-continuous-backups \
  --region "${AWS_REGION}" \
  --table-name "${LOCK_TABLE}" \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

cat <<EOF
Backend bootstrap completed.

Next steps:
1. Add a restrictive bucket policy for the approved plan/apply/recovery roles.
2. Enable CloudTrail data events and cross-account/cross-region replication.
3. Record the bucket, region, KMS key, and lock table in the service catalogue.
4. Test state restore in a non-production account.
5. Retire DynamoDB locking only after every Terraform client supports S3 lockfiles.
EOF
