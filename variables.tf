variable "app_name" {}
variable "region" {}
variable "vpc_cidr" {}
variable "environment" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "instance_type" {}
variable "health_check_type" {
	default = "EC2"
}

variable "private_subnet_cidrs" {
  type = list
}

variable "public_subnet_cidrs" {
  type = list
}

variable "availability_zones" {
  type = list
}

variable "public_key_path" {
	default = "~/.ssh/id_rsa.pub"
}

variable "backend_port" {
  description = "The port the service on the EC2 instances listen on."
  default     = 80
}

variable "awslogs_retention_days" {
  default = 1
}