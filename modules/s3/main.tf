resource "aws_s3_bucket" "tf_s3" {
  bucket = "${var.name}-terraform-bucket"
}

