# This file creates S3 bucket to hold terraform states
# and DynamoDB table to keep the state locks.
resource "aws_s3_bucket" "terraform_infra" {
  bucket = "news432111-terraform-infra-na"
  force_destroy = true

### terraform backend code
  tags = {
     Name = "Bucket for terraform states of news4321"
     createdBy = "infra-news4321/backend-support"
  }
}

# To allow rolling back states
resource "aws_s3_bucket_versioning" "terraform_infra" {
  bucket = aws_s3_bucket.terraform_infra.id
  versioning_configuration {
    status = "Enabled"
  }
}

# To cleanup old states eventually
resource "aws_s3_bucket_lifecycle_configuration" "terraform_infra" {
  depends_on = [aws_s3_bucket_versioning.terraform_infra]

  bucket = aws_s3_bucket.terraform_infra.id
  rule {
    id = "rule-1"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_infra" {
  bucket = aws_s3_bucket.terraform_infra.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_infra" {
  bucket = aws_s3_bucket.terraform_infra.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "terraform_infra" {
  depends_on = [
    aws_s3_bucket_ownership_controls.terraform_infra,
    aws_s3_bucket_public_access_block.terraform_infra,
  ]

  bucket = aws_s3_bucket.terraform_infra.id
  acl    = "private"
}

resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "news4321-terraform-locks"
  # up to 25 per account is free
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
     Name = "Terraform Lock Table"
     createdBy = "infra-news4321/backend-support"
  }
}
