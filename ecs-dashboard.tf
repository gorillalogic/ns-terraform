resource "aws_ecs_task_definition" "sensor_analytics" {
  family                   = "sensor_analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

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
        "containerPort": 3000
      }
    ],
    "environment": [
      {
        "name": "GF_SERVER_PROTOCOL",
        "value": "http"
      },
      {
        "name": "GF_SERVER_HTTP_PORT",
        "value": "3000"
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
        "awslogs-region": "${var.aws_region}",
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
        "containerPort": 8086
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
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "influxdb"
      }
    }
  },
  {
    "cpu": 256,
    "memory": 512,
    "image": "${aws_ecr_repository.kinesis_consumer.repository_url}:latest",
    "name": "kinesis-consumer",
    "networkMode": "awsvpc",
    "environment": [
      {
        "name": "INFLUXDB_HOST",
        "value": "localhost"
      },
      {
        "name": "INFLUXDB_PORT",
        "value": "8086"
      },
      {
        "name": "INFLUXDB_DB",
        "value": "sensordb"
      },
      {
        "name": "INFLUXDB_USER",
        "value": "noise"
      },
      {
        "name": "INFLUXDB_PASS",
        "value": "42noisealert42"
      },
      {
        "name": "KINESIS_STREAM_NAME",
        "value": "mqtt-ingestor"
      },
      {
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/kinesis-consumer",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "kinesis-consumer"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name            = "tf-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sensor_analytics.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.grafana.id
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_alb_listener.grafana]
}

// Load Balancer Listeners
resource "aws_alb_listener" "grafana" {
  load_balancer_arn = aws_lb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.grafana.id
    type             = "forward"
  }
}

// Target Groups
resource "aws_alb_target_group" "grafana" {
  name        = "grafana"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}
