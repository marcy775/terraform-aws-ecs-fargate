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

# GitHub Actions Terraform
resource "aws_iam_role" "tf_cicd_oidc_role" {
  name = "${var.name}-tf-oidc-role"

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

resource "aws_iam_role_policy" "tf_backend_policy" {
  name = "${var.name}-tf-backend-policy"
  role = aws_iam_role.tf_cicd_oidc_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 state
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name}-terraform-state",
          "arn:aws:s3:::${var.name}-terraform-state/*"
        ]
      },
      # DynamoDB lock
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.name}-lock"
      }
    ]
  })
}

resource "aws_iam_role_policy" "tf_resource_policy" {
  name = "${var.name}-tf-resource-policy"
  role = aws_iam_role.tf_cicd_oidc_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "elasticloadbalancing:*",
          "ecr:*",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}
