output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}
output "alb_arn" {
  value = aws_lb.this.arn
}

output "tg_arn" {
  value = aws_lb_target_group.app_nginx.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "alb_url" {
  value = "http://${aws_lb.this.dns_name}/"
}
