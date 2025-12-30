data "aws_caller_identity" "current" {}


# ECR task execution role
resource "aws_iam_role" "tf_ecs_role" {
  name = "${var.name}-ecs-task-execution-role"

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
  role = aws_iam_role.tf_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# GitHub Actions role
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [ "sts.amazonaws.com" ]
}


# GitHub Actions ECS/ECR
resource "aws_iam_role" "ecs_cicd_oidc_role" {
  name = "${var.name}-ecs-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:marcy775/terraform-aws-ecs-fargate:ref:refs/heads/*",
              "repo:marcy775/terraform-aws-ecs-fargate:ref:refs/pull/*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_cicd_policy" {
  name = "${var.name}-ecs-oidc-policy"
  role = aws_iam_role.ecs_cicd_oidc_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR push
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage"        
        ]
        Resource = "*"
      },
      # ECS deploy
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition"    
        ]
        Resource = "*"
      }
    ]
  })
}