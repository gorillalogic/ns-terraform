terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/Users/emmanuel.mora/.aws/credentials"
  profile                 = "noise"
}

resource "aws_ecs_cluster" "main" {
  name = "tf-ecs-cluster"
}

resource "aws_alb" "main" {
  name            = "tf-ecs-noise"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}
