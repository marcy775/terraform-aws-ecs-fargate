resource "aws_iam_role" "tf_ecs_role" {
  name = "${var.name}-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tf_ecs_role_add" {
  count = length(var.policy_arn)
  role = aws_iam_role.tf_ecs_role.name
  policy_arn = var.policy_arn[count.index]
}