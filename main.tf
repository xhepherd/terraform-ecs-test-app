provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "ads-app"
  environment = "dev"

  # This is the convention we use to know what belongs to each other
  ec2_resources_name = "${local.name}-${local.environment}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name = "${local.name}-ecs"

  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]

  #enable_nat_gateway = false # this is faster, but should be "true" for real
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = local.environment
    Name        = local.name
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  
  name = "${local.name}-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.vpc.default_security_group_id]
  
  target_groups = [
    {
      name_prefix      = "dev"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = local.environment
  }
}


#----- ECS --------
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  name   = local.name
}

module "ec2-profile" {
  source = "./modules/ecs-instance-profile"
  name   = local.name
}

#----- ECS  Services--------

module "ads-app" {
  source     = "./modules/ads-app"
  cluster_id = module.ecs.this_ecs_cluster_id
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
  instance_type        = "t2.micro"
  security_groups      = [module.vpc.default_security_group_id]
  iam_instance_profile = module.ec2-profile.this_iam_instance_profile_id
  user_data            = data.template_file.user_data.rendered

  #load_balancers = [module.alb.this_lb_id]
  target_group_arns = module.alb.target_group_arns

  # Auto scaling group
  asg_name                  = local.ec2_resources_name
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = local.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = local.name
      propagate_at_launch = true
    },
  ]
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = module.vpc.default_security_group_id
}

resource "aws_key_pair" "ecs_key" {
  key_name = "${local.name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = local.name
  }
}

output "lb_dns_name" {
  value = "${module.alb.this_lb_dns_name}"
}
