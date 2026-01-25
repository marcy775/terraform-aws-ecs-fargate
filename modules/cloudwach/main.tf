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

# 5xx error
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [var.sns_topic_arn]
}

# Latency P99 < 1.0s
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.name}-alb-latency-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  
  extended_statistic  = "p99" 
  threshold           = "1.0" 

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [var.sns_topic_arn]
}