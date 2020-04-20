app_name = "ads-app"
region = "us-east-1"
environment = "dev"

vpc_cidr = "10.1.0.0/16"
private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

backend_port = 80
awslogs_retention_days = 1
max_size = 1
min_size = 1
desired_capacity = 1
instance_type = "t2.micro"

public_key_path = "~/.ssh/id_rsa.pub"