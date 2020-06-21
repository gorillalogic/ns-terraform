variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  default     = "002631123367"
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

variable "mqtt_topic" {
  description = "Topic that devices push events to."
  default     = "sensors/noise"
}

variable "ecs_cluster_name" {
  default     = "tf-ecs-cluster"
}

variable "default_tags" {
  type = map(string)
  default = {
    initiative: "ideas",
    team: "noisealert",
    version: "0.2"
  }
}

# Secrets
variable "secret_grafana_admin_pass" {
  description = "Default Grafana Admin Password"
}

variable "secret_influxdb_admin_pass" {
  description = "Default InfluxDB Admin Password"
}
