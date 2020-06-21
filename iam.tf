resource "aws_iam_role" "grafana_ecs_task_execution_role" {
  name               = "grafana-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "grafana_ecs_task_execution" {
  name   = "grafana-ecs-task-execution"
  role   = aws_iam_role.grafana_ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.grafana-cloudwatch_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "grafana-cloudwatch_role_policy" {
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
