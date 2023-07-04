output "lb_dns_name" {
    value = module.alb.lb_dns_name
}

output "app_url" {
    value = format("%s%s:%d","http://", module.alb.lb_dns_name, 80)
}

output "aws_ecr_repository" {
  value = aws_ecr_repository.this.repository_url
}