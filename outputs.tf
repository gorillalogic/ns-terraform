output "alb_hostname" {
  value = "http://${aws_alb.main.dns_name}"
  description = "URL where graphana dashboard can be accessed."
}


