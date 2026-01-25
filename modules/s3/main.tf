# s3 
resource "aws_s3_bucket" "tf_s3" {
  bucket = "${var.name}-bucket"
}

# s3 versions
resource "aws_s3_bucket_versioning" "tf_s3_versioning" {
  bucket = aws_s3_bucket.tf_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# s3 lifecycle rule
resource "aws_s3_bucket_lifecycle_configuration" "tf_s3_lifecycle" {
  bucket = aws_s3_bucket.tf_s3.id

  rule {
    id = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 1
      newer_noncurrent_versions = 2
    }
  }
}

