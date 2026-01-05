# sns topic
resource "aws_sns_topic" "tf_topic" {
  name = "${var.name}-topic"
}

# sns subscription
resource "aws_sns_topic_subscription" "tf_email_sub" {
  topic_arn = aws_sns_topic.tf_topic.arn
  protocol = "email"
  endpoint = var.email
}