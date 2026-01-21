############################
# ALB Security Group
############################
resource "aws_security_group" "alb" {
  name        = "cheap-fullstack-alb-sg"
  description = "ALB public access"
  vpc_id      = aws_vpc.this.id

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
# Allow ALB → App EC2 (nginx host:80)
############################
# IMPORTANT:
# - Keep ONLY this rule for ALB→App:80
# - Do NOT duplicate port 80 ingress inside aws_security_group.app inline rules
resource "aws_security_group_rule" "app_from_alb_80" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to reach nginx on app (80)"
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
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "cheap-fullstack-alb"
  }
}

############################
# Target Group → nginx host:80
############################
resource "aws_lb_target_group" "app_nginx" {
  name_prefix = "cftg-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
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
# Attach Instance → Target Group (port 80)
############################
resource "aws_lb_target_group_attachment" "app_instance" {
  target_group_arn = aws_lb_target_group.app_nginx.arn
  target_id        = aws_instance.app.id
  port             = 80
}

############################
# Output
############################
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
