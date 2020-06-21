output "dashboard" {
  value = "http://${aws_lb.main.dns_name}"
  description = "URL where graphana dashboard can be accessed."
}

output "ecr_registry" {
  value = "${aws_ecr_repository.kinesis_consumer.repository_url}"
  description = "URL of the ECR repository where the kinesis image can be accessed."
}

output "certificate" {
  value = "${aws_iot_certificate.pi_collector.certificate_pem}"
  description = "Thing pi_collector certificate."
}

output "private_key" {
  value = "${aws_iot_certificate.pi_collector.private_key}"
  description = "Thing pi_collector private key."
}

output "public_key" {
  value = "${aws_iot_certificate.pi_collector.public_key}"
  description = "Thing pi_collector public key."
}
