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

// Policies
data "aws_iam_policy_document" "ecs_cloudwatch_policy" {
   statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.grafana.arn,
      aws_cloudwatch_log_group.influxdb.arn,
      aws_cloudwatch_log_group.kinesis_consumer.arn,
    ]
  }
}

data "aws_iam_policy_document" "ecs_kinesis_policy" {
  statement {
    actions = [
      "kinesis:Get*",
      "kinesis:DescribeStream"
    ]

    resources = [
      aws_kinesis_stream.mqtt_ingestor.arn
    ]
  }
}

data "aws_iam_policy_document" "ecs_ecr_policy" {
  statement {
    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "iot_kinesis_policy" {
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
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "iot_kinesis_role" {
  name = "iot_kinesis_role"
  assume_role_policy = data.aws_iam_policy_document.iot_assume_role_policy.json
}

// Attach Policies to Roles
resource "aws_iam_role_policy" "attach_cloudwatch_to_execution_ecs" {
  name   = "attach_cloudwatch_to_ecs"
  role   = aws_iam_role.ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.ecs_cloudwatch_policy.json
}

resource "aws_iam_role_policy" "attach_ecr_to_execution_ecs" {
  name   = "attach_ecr_to_ecs"
  role   = aws_iam_role.ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.ecs_ecr_policy.json
}

resource "aws_iam_role_policy" "attach_kinesis_to_ecs" {
  name   = "attach_kinesis_to_ecs"
  role   = aws_iam_role.ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_kinesis_policy.json
}

resource "aws_iam_role_policy" "attach_kinesis_to_iot" {
  name   = "attach_kinesis_to_iot"
  role   = aws_iam_role.iot_kinesis_role.name
  policy = data.aws_iam_policy_document.iot_kinesis_policy.json
}
