// AssumeRole Policies
data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iot_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

// Policies
data "aws_iam_policy_document" "ecs_cloudwatch_role_policy" {
   statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.grafana.arn,
      aws_cloudwatch_log_group.influxdb.arn
    ]
  }
}

data "aws_iam_policy_document" "iot_kinesis_role_policy" {
  statement {
    actions = [
      "kinesis:PutRecord"
    ]

    resources = [
      aws_kinesis_stream.mqtt_ingestor.arn
    ]
  }
}

// Roles
resource "aws_iam_role" "grafana_ecs_task_execution_role" {
  name = "grafana_ecs_task_execution_role-ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "iot_kinesis_role" {
  name = "iot_kinesis_role"
  assume_role_policy = data.aws_iam_policy_document.iot_assume_role_policy.json
}

resource "aws_iam_role" "kinesis_consumer_lambda_role" {
  name = "kinesis_consumer_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

// Attach Policies to Roles
resource "aws_iam_role_policy" "grafana_ecs_task_execution" {
  name = "grafana-ecs-task-execution"
  role = aws_iam_role.grafana_ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.ecs_cloudwatch_role_policy.json
}

resource "aws_iam_role_policy" "iot_kinesis" {
  name = "iot_kinesis"
  role = aws_iam_role.iot_kinesis_role.name
  policy = data.aws_iam_policy_document.iot_kinesis_role_policy.json
}
