output "tf_alb_tg" {
  value = aws_lb_target_group.tf_alb_tg
}

output "alb_sg" {
  value = aws_security_group.alb_sg
}

output "aws_lb_listener" {
  value = aws_lb_listener.tf_alb_listener
}

output "alb_arn_suffix" {
  value = aws_lb.tf_alb.arn_suffix
}