# ECR repository
resource "aws_ecr_repository" "tf_ecr" {
  name                 = "${var.name}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "tf_ecr_lifecycle" {
  repository = aws_ecr_repository.tf_ecr.name

  policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last 10 images",
                "selection": {
                    "tagStatus": "any",
                    "countType": "imageCountMoreThan",
                    "countNumber": 10
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
    EOF
}
