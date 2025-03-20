terraform {
  backend "s3" {
    bucket         = "zero9905-terraformstate"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "zero9905-terraformstate"
    encrypt        = true
    role_arn       = aws_iam_role.terraform_backend_role.arn # ✅ IAM Role 사용
  }
}

resource "aws_s3_bucket" "terraform_state" { 
  bucket = "zero9905-terraformstate"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "enabled" { 
  bucket = aws_s3_bucket.terraform_state.id 
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" { 
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "terraform_state_policy" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetBucketPolicy",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::zero9905-terraformstate",
        "arn:aws:s3:::zero9905-terraformstate/*"
      ]
    }
  ]
}
POLICY
}




resource "aws_dynamodb_table" "terraform_lock" {
  name         = "zero9905-terraformstate"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
