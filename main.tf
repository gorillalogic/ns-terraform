terraform {
  required_version = ">= 0.12"

  backend "local" {
    path = ".secrets/terraform.tfstate"
  }
}

resource "aws_lb" "main" {
  name            = "tf-ecs-noise"
  load_balancer_type = "application"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
  capacity_providers = [aws_ecs_capacity_provider.provider.name]
}
