variable "logs_retention_in_days" {
  type        = number
  default     = 7
  description = "Specifies the number of days you want to retain log events"
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/fargate/service/grafana"
  retention_in_days = var.logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "influxdb" {
  name              = "/fargate/service/influxdb"
  retention_in_days = var.logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "kinesis_consumer" {
  name              = "/fargate/service/kinesis-consumer"
  retention_in_days = var.logs_retention_in_days
}
