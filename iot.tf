data "aws_iot_endpoint" "mqtt_endpoint" {
  endpoint_type = "iot:Data-ATS"
}

resource "aws_iot_thing" "pi_collector" {
  name = "pi_collector"
}

resource "aws_iot_topic_rule" "kinesis_push_rule" {
  name = "kinesis_push_rule"
  enabled = true
  sql = "SELECT * FROM '${var.mqtt_topic}'"
  sql_version = "2015-10-08"

  kinesis {
    stream_name = "mqtt-ingestor"
    partition_key = "e4ecd436-f618-4ae5-b5bf-53742384cffe"
    role_arn = aws_iam_role.iot_kinesis_role.arn
  }
}

data "aws_iam_policy_document" "iot_thing_connect_policy" {
  statement {
    actions = [
      "iot:Connect",
    ]

    resources = [
      "arn:aws:iot:${var.aws_region}:${var.aws_account_id}:client/${aws_iot_thing.pi_collector.name}"
    ]
  }
}

data "aws_iam_policy_document" "iot_thing_pub_policy" {
  statement {
    actions = [
      "iot:Publish",
      "iot:Receive"
    ]

    resources = [
      "arn:aws:iot:${var.aws_region}:${var.aws_account_id}:topic/sensors/noise"
    ]
  }
}

resource "aws_iot_certificate" "pi_collector" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "pi_collector" {
  principal = aws_iot_certificate.pi_collector.arn
  thing     = aws_iot_thing.pi_collector.name
}

resource "aws_iot_policy" "iot_thing_connect_policy" {
  name = "iot-thing-connect-policy"
  policy = data.aws_iam_policy_document.iot_thing_connect_policy.json
}

resource "aws_iot_policy" "iot_thing_pub_policy" {
  name = "iot-thing-pub-policy"
  policy = data.aws_iam_policy_document.iot_thing_pub_policy.json
}

resource "aws_iot_policy_attachment" "connect" {
  policy = aws_iot_policy.iot_thing_connect_policy.name
  target = aws_iot_certificate.pi_collector.arn
}

resource "aws_iot_policy_attachment" "pub" {
  policy = aws_iot_policy.iot_thing_pub_policy.name
  target = aws_iot_certificate.pi_collector.arn
}
