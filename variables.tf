variable "app_name" {
  description = "Application name prefix for resources"
  type        = string
  default     = "game-score-tracker"
}

variable "aws_region" {
  description = "AWS Region per environment"
  type        = map(string)
  default = {
    "dev"  = "eu-west-2"
    "stg"  = "eu-west-1"
    "prod" = "eu-central-1"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "profile" {
  description = "AWS Profiles for workspaces"
  type        = map(string)
  default = {
    "dev"  = "personal"
    "stg"  = "personal"
    "prod" = "personal"
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for resources"
  type        = bool
  default     = false
}

variable "force_delete_ecr" {
  description = "Force delete ECR repository with images"
  type        = bool
  default     = true
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB"
  type        = bool
  default     = false
}

variable "destroy_mode" {
  description = "Set to true when planning to destroy infrastructure (disables protections)"
  type        = bool
  default     = false
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.12"
}

locals {
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Application = "game-score-tracker"
  }
}
