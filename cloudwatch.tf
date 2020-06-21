variable "logs_retention_in_days" {
  type        = number
  default     = 7
  description = "Specifies the number of days you want to retain log events"
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/noise-alert/grafana"
  retention_in_days = var.logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "influxdb" {
  name              = "/noise-alert/influxdb"
  retention_in_days = var.logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "kinesis_consumer" {
  name              = "/noise-alert/kinesis-consumer"
  retention_in_days = var.logs_retention_in_days
}
