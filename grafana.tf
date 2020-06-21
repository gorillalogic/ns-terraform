resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.grafana_ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "memory": 512,
    "image": "${var.grafana_image}",
    "name": "grafana",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ],
    "environment": [
      {
        "name": "GF_SERVER_PROTOCOL",
        "value": "http"
      },
      {
        "name": "GF_SERVER_HTTP_PORT",
        "value": "${var.app_port}"
      },
      {
        "name": "GF_SECURITY_ADMIN_USER",
        "value": "noise"
      },
      {
        "name": "GF_SECURITY_ADMIN_PASSWORD",
        "value": "42noisealert42"
      },
      {
        "name": "GF_SECURITY_LOGIN_REMEMBER_DAYS",
        "value": "30"
      },
      {
        "name": "GF_SECURITY_COOKIE_USERNAME",
        "value": "grafana_user"
      },
      {
        "name": "GF_SECURITY_REMEMBER_NAME",
        "value": "grafana_remember"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/grafana",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "grafana"
      }
    }
  },
  {
    "cpu": 256,
    "memory": 512,
    "image": "${var.influxdb_image}",
    "name": "influxdb",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 8086,
        "hostPort": 8086
      }
    ],
    "environment": [
      {
        "name": "INFLUXDB_DB",
        "value": "sensordb"
      },
      {
        "name": "INFLUXDB_USER",
        "value": "noise"
      },
      {
        "name": "INFLUXDB_USER_PASSWORD",
        "value": "42noisealert42"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/influxdb",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "influxdb"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name            = "tf-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.grafana.id
    container_name   = "grafana"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front_end]
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.grafana.id
    type             = "forward"
  }
}

resource "aws_alb_target_group" "grafana" {
  name        = "alb-grafana"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}