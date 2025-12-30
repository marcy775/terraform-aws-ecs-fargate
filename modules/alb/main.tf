# ALB security group
resource "aws_security_group" "alb_sg" {
  name = "${var.name}-alb-sg"
  description = "ALB security group"
  vpc_id = var.vpc_id
}

# ALB sg ingress
resource "aws_vpc_security_group_ingress_rule" "alb_inbound" {
  security_group_id = aws_security_group.alb_sg.id

  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
}

# ALB sg egress
resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

# ALB
resource "aws_lb" "tf_alb" {
  name = "${var.name}-alb"
  internal = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets = var.subnet_ids
  
  enable_deletion_protection = false
  
  tags = {
    Name = "${var.name}-alb"
  }
}

# ALB tg
resource "aws_lb_target_group" "tf_alb_tg" {
  name = "${var.name}-alb-tg"
  target_type = "ip"

  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = "/health"
    protocol = "HTTP"
    matcher = "200"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# ALB listener
resource "aws_lb_listener" "tf_alb_listener" {
  load_balancer_arn = aws_lb.tf_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tf_alb_tg.arn
  }
}