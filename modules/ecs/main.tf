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
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name = aws_cloudwatch_log_group.tf_ecs_log.name
      }
    }
  }
}

# ECS Security Group
resource "aws_security_group" "tf_ecs_sg" {
  name = "${var.name}-ecs-task-sg"
  vpc_id = var.vpc_id
  description = "ECS security group"
}

# ECS sg ingress
resource "aws_vpc_security_group_ingress_rule" "ecs_inbound" {
  security_group_id = aws_security_group.tf_ecs_sg.id

  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  referenced_security_group_id = var.alb_sg_id
}

# ECS sg egress
resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.tf_ecs_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "tf_ecs_td" {
  family = "${var.name}-ecs-family"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  execution_role_arn = var.role_arn

  container_definitions = jsonencode([
    {
        name = "${var.name}-container"
        image = "${var.ecr_repository_url}:latest"
        portMappings = [
            {
                containerPort = 80
            }
        ]

        essential = true

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

# ECS service
resource "aws_ecs_service" "tf_ecs_service" {
  name = "${var.name}-ecs-service"
  cluster = aws_ecs_cluster.tf_ecs.id
  task_definition = aws_ecs_task_definition.tf_ecs_td.arn
  desired_count = 2
  launch_type = "FARGATE"
  platform_version = "1.4.0"

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }

  network_configuration {
    security_groups = [aws_security_group.tf_ecs_sg.id]
    subnets = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name = "${var.name}-container"
    container_port = 80
  }
}