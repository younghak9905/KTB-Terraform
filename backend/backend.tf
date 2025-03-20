variable "create_backend_resources" {
  description = "백엔드 S3 버킷과 DynamoDB 테이블을 Terraform이 생성할지 여부입니다. 이미 존재하면 false로 유지합니다."
  type        = bool
  default     = false
}

# S3 Bucket: create_backend_resources가 true일 때만 생성합니다.
resource "aws_s3_bucket" "terraform_state" {
  count         = var.create_backend_resources ? 1 : 0
  bucket        = "zero9905-terraformstate"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "enabled" {
  count  = var.create_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count  = var.create_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  count                   = var.create_backend_resources ? 1 : 0
  bucket                  = aws_s3_bucket.terraform_state[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 만약 S3 버킷 정책이 필요하다면, 아래와 같이 특정 IAM 주체만 허용하는 방식으로 작성하세요.
# 현재는 백엔드로 사용하기 때문에 별도 정책 없이 IAM 권한으로 접근을 제어하는 것이 권장됩니다.
#
# resource "aws_s3_bucket_policy" "terraform_state_policy" {
#   count  = var.create_backend_resources ? 1 : 0
#   bucket = aws_s3_bucket.terraform_state[0].id
#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "arn:aws:iam::<YOUR-AWS-ACCOUNT-ID>:role/YourTerraformRole"
#       },
#       "Action": [
#         "s3:GetBucketPolicy",
#         "s3:ListBucket",
#         "s3:GetObject",
#         "s3:PutObject"
#       ],
#       "Resource": [
#         "arn:aws:s3:::zero9905-terraformstate",
#         "arn:aws:s3:::zero9905-terraformstate/*"
#       ]
#     }
#   ]
# }
# POLICY
# }

# DynamoDB 테이블: create_backend_resources가 true일 때만 생성합니다.
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "zero9905-terraform-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true  # 삭제 방지
  }
}