variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "awslogs_retention_days" {
  description = "AWS Cloudwatch region where to store container logs"
  type        = string
  default     = 1
}

variable "awslogs_region" {
  description = "AWS Cloudwatch region where to store container logs"
  type        = string
}

variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}

variable "target_group_arn" {
  description = "The load balancer target group arn"
  type        = string
}

variable "container_port" {
  description = "The port container listen on."
  default     = 80
}

variable "host_port" {
  description = "The host port of container."
  default     = 80
}