terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true

    # Backend bucket, key, region, KMS key, and the transitional DynamoDB
    # lock table are supplied through -backend-config. Backend blocks cannot
    # use normal Terraform variables.
  }
}
