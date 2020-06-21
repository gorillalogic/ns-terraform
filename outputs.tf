output "alb_hostname" {
  value = "http://${aws_alb.main.dns_name}"
  description = "URL where graphana dashboard can be accessed."
}

output "ecr_repository_kinesis_consumer" {
  value = "${aws_ecr_repository.kinesis_consumer.repository_url}"
  description = "URL of the ECR repository where the kinesis image can be accessed."
}
