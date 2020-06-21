resource "aws_kinesis_stream" "mqtt_ingestor" {
  name = "mqtt-ingestor"
  shard_count = 1

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}
