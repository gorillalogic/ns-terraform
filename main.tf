terraform {
  required_version = ">= 0.12"
}

resource "aws_alb" "main" {
  name            = "tf-ecs-noise"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_ecs_cluster" "main" {
  name = "tf-ecs-cluster"
}
