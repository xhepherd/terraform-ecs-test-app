resource "aws_cloudwatch_log_group" "ads_app" {
  name              = "ads_app"
  retention_in_days = 1
}

resource "aws_ecr_repository" "ads_app" {
  name = "ads_app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_task_definition" "ads_app" {
  family = "ads_app"

  container_definitions = <<EOF
[
  {
    "name": "ads_app",
    "image": "179328159724.dkr.ecr.us-east-1.amazonaws.com/ads_app:v0.2",
    "cpu": 0,
    "memory": 128,
    "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "ads_app",
        "awslogs-region": "us-east-1"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "ads_app" {
  name = "ads_app"
  cluster = var.cluster_id
  task_definition = aws_ecs_task_definition.ads_app.arn

  desired_count = 1

  deployment_maximum_percent = 100
  deployment_minimum_healthy_percent = 0
}

