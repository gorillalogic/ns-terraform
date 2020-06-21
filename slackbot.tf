data "aws_caller_identity" "current" { }

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_role_for_lambda" {
  name = "iam_role_for_lambda_api_slackbot"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
}

# This is a second lambda function that will run the code
# `slackbot_lambda.post_handler`
module "lambda_post" {
  source  = "./lambda"
  name    = "slackbot_lambda"
  handler = "post_handler"
  runtime = "python3.7"
  role    = aws_iam_role.iam_role_for_lambda.arn
}

data "aws_iam_policy_document" "slackbot_lambda_policy_document" {
  statement {
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      "arn:aws:dynamodb:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "slackbot_lambda_policy" {
  name        = "slackbot_lambda"
  description = "Policy for the Noise Alert Slackbot"

  policy = data.aws_iam_policy_document.slackbot_lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_role_for_lambda.name
  policy_arn = aws_iam_policy.slackbot_lambda_policy.arn
}


# Now, we need an API to expose those functions publicly
resource "aws_api_gateway_rest_api" "slackbot_api" {
  name = "Noise Alert SlackBot API"
}

# The API requires at least one "endpoint", or "resource" in AWS terminology.
# The endpoint created here is: /noisereport
resource "aws_api_gateway_resource" "slackbot_api_res_noisereport" {
  rest_api_id = aws_api_gateway_rest_api.slackbot_api.id
  parent_id   = aws_api_gateway_rest_api.slackbot_api.root_resource_id
  path_part   = "noisereport"
}

# Until now, the resource created could not respond to anything. We must set up
# a HTTP method (or verb) for that!

# This is the code for method POST /noisereport
module "slackbot_post" {
  source      = "./api_method"
  rest_api_id = aws_api_gateway_rest_api.slackbot_api.id
  resource_id = aws_api_gateway_resource.slackbot_api_res_noisereport.id
  method      = "POST"
  path        = aws_api_gateway_resource.slackbot_api_res_noisereport.path
  lambda      = module.lambda_post.name
  region      = var.aws_region
  account_id  = data.aws_caller_identity.current.account_id
}

# We can deploy the API now! (i.e. make it publicly available)
resource "aws_api_gateway_deployment" "slackbot_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.slackbot_api.id
  stage_name  = "production"
  description = "Deploy methods: ${module.slackbot_post.http_method}"
}

module "dynamodb_table" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-dynamodb.git?ref=tags/0.10.0"
  stage                        = "prod"
  name                         = "noise_alert_report_table"
  hash_key                     = "DataID"
  range_key                    = "CreatedAt"
  range_key_type                = "N"
  enable_autoscaler            = false
  tags = var.default_tags
}