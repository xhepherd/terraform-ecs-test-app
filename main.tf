provider "aws" {
  region = var.region
}

locals {
  # This is the convention we use to know what belongs to each other
  ec2_resources_name = "${var.app_name}-${var.environment}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name = "${var.app_name}-ecs"

  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Name        = var.app_name
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  
  name = "${var.app_name}-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.vpc.default_security_group_id]
  
  target_groups = [
    {
      name_prefix      = "dev"
      backend_protocol = "HTTP"
      backend_port     = var.backend_port
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = var.backend_port
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.environment
  }
}

#----- ECS --------
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  name   = var.app_name
}

module "ec2-profile" {
  source = "./modules/ecs-instance-profile"
  name   = var.app_name
}

#----- ECS  Services--------

module "ads-app" {
  name = var.app_name
  source     = "./modules/ads-app"
  awslogs_retention_days = var.awslogs_retention_days
  awslogs_region = var.region
  container_port = var.backend_port
  host_port = var.backend_port
  cluster_id = module.ecs.this_ecs_cluster_id
  target_group_arn = element(module.alb.target_group_arns, 0)
}

#----- ECS  Resources--------

#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = local.ec2_resources_name

  # Launch configuration
  lc_name = local.ec2_resources_name

  image_id             = data.aws_ami.amazon_linux_ecs.id
  key_name             = aws_key_pair.ecs_key.key_name
  instance_type        = var.instance_type
  security_groups      = [module.vpc.default_security_group_id]
  iam_instance_profile = module.ec2-profile.this_iam_instance_profile_id
  user_data            = data.template_file.user_data.rendered

  # Auto scaling group
  asg_name                  = local.ec2_resources_name
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = var.health_check_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = var.app_name
      propagate_at_launch = true
    },
  ]
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = var.backend_port
  to_port                  = var.backend_port
  protocol                 = "TCP"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = module.vpc.default_security_group_id
}

resource "aws_key_pair" "ecs_key" {
  key_name = "${var.app_name}-key"
  public_key = file(var.public_key_path)
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = var.app_name
  }
}