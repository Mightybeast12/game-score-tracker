variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name to monitor"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN to monitor"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "sns_email" {
  description = "Email for SNS notifications"
  type        = string
  default     = ""
}
