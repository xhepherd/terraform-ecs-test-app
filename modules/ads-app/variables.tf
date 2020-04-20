variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}

variable "target_group_arn" {
  description = "The load balancer target group arn"
  type        = string
}