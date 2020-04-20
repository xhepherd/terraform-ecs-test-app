resource "aws_cloudwatch_log_group" "ads_app" {
  name              = var.name
  retention_in_days = var.awslogs_retention_days
}

resource "aws_ecr_repository" "ads_app" {
  name = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_task_definition" "ads_app" {
  family = var.name

  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${aws_ecr_repository.ads_app.repository_url}:latest",
    "cpu": 0,
    "memory": 128,
    "portMappings": [
        {
          "containerPort": ${var.container_port},
          "hostPort": ${var.host_port},
          "protocol": "tcp"
        }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.name}",
        "awslogs-region": "${var.awslogs_region}"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "ads_app" {
  name = var.name

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.container_port
  }

  cluster = var.cluster_id
  task_definition = aws_ecs_task_definition.ads_app.arn

  desired_count = 1

  deployment_maximum_percent = 100
  deployment_minimum_healthy_percent = 0
}