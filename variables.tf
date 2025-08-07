variable "app_name" {
  description = "Application name prefix for resources"
  type        = string
  default     = "tennis"
}

variable "aws_reqion" {
  description = "AWS Region per environment"
  type        = map(string)
  default = {
    "dev"  = "eu-west-2"
    "stg"  = "eu-west-1"
    "prod" = "eu-central-1"
  }
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
