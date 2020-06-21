resource "aws_ecr_repository" "kinesis_consumer" {
  name  = "kinesis_consumer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}