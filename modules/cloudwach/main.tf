# ECS CPU
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name = "${var.name}-ecs-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  period = 60
  threshold = 80
  statistic = "Average"
  namespace = "AWS/ECS"
  metric_name = "CPUUtilization"

  dimensions = {
    ClusterName = "${var.name}-ecs"
    ServiceName = "${var.name}-ecs-service"
  }

  alarm_actions = [var.sns_topic_arn]
}

# ECS Memory
resource "aws_cloudwatch_metric_alarm" "ecs_mem" {
  alarm_name = "${var.name}-ecs-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  period = 60
  threshold = 80
  statistic = "Average"
  namespace = "AWS/ECS"
  metric_name = "MemoryUtilization"

  dimensions = {
    ClusterName = "${var.name}-ecs"
    ServiceName = "${var.name}-ecs-service"
  }

  alarm_actions = [var.sns_topic_arn]
}