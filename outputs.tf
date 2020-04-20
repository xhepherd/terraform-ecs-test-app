output "lb_dns_name" {
  value = module.alb.this_lb_dns_name
}

output "ecr_repository_url" {
  value = module.ads-app.ecr_repository_url
}