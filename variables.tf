variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  default     = "961622453478"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "grafana_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "grafana/grafana:latest"
}

variable "influxdb_image" {
  description = "Influx image to run in the ECS cluster"
  default     = "influxdb:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 3000
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "512"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "1024"
}

variable "mqtt_topic" {
  description = "Topic that devices push events to."
  default     = "sensors/noise"
}
