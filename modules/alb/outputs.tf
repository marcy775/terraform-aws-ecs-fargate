output "tf_alb_tg" {
  value = aws_lb_target_group.tf_alb_tg
}

output "alb_sg" {
  value = aws_security_group.alb_sg
}