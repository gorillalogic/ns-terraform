data "archive_file" "zip" {
  type = "zip"
  source_file = "kinesis_consumer.py"
  output_path = "kinesis_consumer.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "kinesis_consumer"

  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role = aws_iam_role.kinesis_consumer_lambda_role.arn
  handler = "kinesis_consumer.lambda_handler"
  runtime = "python3.6"

  environment {
    variables = {
      greeting = "Hello!"
    }
    # TODO: Implement actual lambda function to pop records from
    # kinesis and put as batches in influxdb.
  }
}
