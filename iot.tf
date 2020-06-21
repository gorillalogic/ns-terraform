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
