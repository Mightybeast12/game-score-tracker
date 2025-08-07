variable "name" {
  description = "Name for the frontend service"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "image_uri" {
  description = "URI of the container image"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory for the task"
  type        = string
  default     = "512"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "cpu_target_value" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70.0
}