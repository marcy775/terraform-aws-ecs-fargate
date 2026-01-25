# dynamodb
resource "aws_dynamodb_table" "tf_dynamo_tb" {
  name = "${var.name}-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}