variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "force_delete" {
  description = "Force delete ECR repository even if it contains images"
  type        = bool
  default     = true
}