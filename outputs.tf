output "dashboard" {
  value = "${aws_lb.main.dns_name}"
  description = "URL where graphana dashboard can be accessed."
}

output "ecr_registry" {
  value = "${aws_ecr_repository.kinesis_consumer.repository_url}"
  description = "URL of the ECR repository where the kinesis image can be accessed."
}

output "mqtt_endpoint" {
  value = "${data.aws_iot_endpoint.mqtt_endpoint.endpoint_address}"
  description = "Endpoint url for mqtt server."
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

output "certificate_leo" {
  value = "${aws_iot_certificate.pi_collector_leo.certificate_pem}"
  description = "Thing pi_collector_leo certificate."
}

output "private_key_leo" {
  value = "${aws_iot_certificate.pi_collector_leo.private_key}"
  description = "Thing pi_collector_leo private key."
}

output "public_key_leo" {
  value = "${aws_iot_certificate.pi_collector_leo.public_key}"
  description = "Thing pi_collector_leo public key."
}