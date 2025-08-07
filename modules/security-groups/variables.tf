variable "name_prefix" {
  description = "Prefix for security group names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}