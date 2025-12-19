# CloudWatch logs
resource "aws_cloudwatch_log_group" "tf_ecs_log" {
  name = "/ecs/${var.name}"
  retention_in_days = 7
}

# ECS cluster
resource "aws_ecs_cluster" "tf_ecs" {
  name = "${var.name}-ecs"
  
  configuration {
    execute_command_configuration {
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name = aws_cloudwatch_log_group.tf_ecs_log.name
      }
    }
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "tf_ecs_td" {
  family = "${var.name}-ecs-family"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  execution_role_arn = var.execution_role_arn
  container_definitions = jsonencode([
    {
        name = "${var.name}-container"
        image = "${var.ecr_repository_url}:latest"
        portMappings = [
            {
                containerPort = 80
            }
        ]

        logConfiguration = {
            logDriver = "awslogs"
            options = {
                awslogs-group = aws_cloudwatch_log_group.tf_ecs_log.name
                awslogs-region = var.region
                awslogs-stream-prefix = "ecs"
            }
        }
    }
  ])
}