############################
# ALB Security Group
############################
resource "aws_security_group" "alb" {
  name        = "cheap-fullstack-alb-sg"
  description = "ALB public access"
  vpc_id      = aws_vpc.this.id # ⬅️ CHANGE HERE (імʼя VPC ресурсу) Done

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cheap-fullstack-alb-sg"
  }
}

############################
# Allow ALB → App EC2 (nginx:8008)
############################
resource "aws_security_group_rule" "app_from_alb_8008" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app.id # ⬅️ CHANGE HERE (SG app EC2) Done
  from_port                = 8008
  to_port                  = 8008
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to reach nginx on app"
}

############################
# Application Load Balancer
############################
resource "aws_lb" "this" {
  name               = "cheap-fullstack-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id # ⬅️ CHANGE HERE (public subnet #1) Done
  ]

  tags = {
    Name = "cheap-fullstack-alb"
  }
}

############################
# Target Group → nginx:8008
############################
resource "aws_lb_target_group" "app_nginx" {
  name        = "cheap-fullstack-tg"
  port        = 8008
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id # ⬅️ CHANGE HERE (імʼя VPC ресурсу) Done
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "8008"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
  }

  tags = {
    Name = "cheap-fullstack-tg"
  }
}

############################
# Listener :80 → Target Group
############################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_nginx.arn
  }
}

############################
# Attach ASG → Target Group
############################
# resource "aws_autoscaling_attachment" "app_to_tg" {
#   autoscaling_group_name = aws_autoscaling_group.app.name   # ⬅️ CHANGE HERE (ASG app)
#   lb_target_group_arn    = aws_lb_target_group.app_nginx.arn
# }
resource "aws_lb_target_group_attachment" "app_instance" {
  target_group_arn = aws_lb_target_group.app_nginx.arn
  target_id        = aws_instance.app.id
  port             = 8008
}

############################
# Output
############################
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
