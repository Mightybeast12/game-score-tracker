variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "stage_name" {
  description = "Stage name for API Gateway deployment"
  type        = string
  default     = "prod"
}

variable "create_game_lambda_invoke_arn" {
  description = "Invoke ARN of the create game Lambda function"
  type        = string
}

variable "create_game_lambda_function_name" {
  description = "Function name of the create game Lambda"
  type        = string
}

variable "score_updater_lambda_invoke_arn" {
  description = "Invoke ARN of the score updater Lambda function"
  type        = string
}

variable "score_updater_lambda_function_name" {
  description = "Function name of the score updater Lambda"
  type        = string
}

variable "get_history_lambda_invoke_arn" {
  description = "Invoke ARN of the get history Lambda function"
  type        = string
}

variable "get_history_lambda_function_name" {
  description = "Name of the get history Lambda function"
  type        = string
}

variable "get_game_lambda_invoke_arn" {
  description = "Invoke ARN of the get game Lambda function"
  type        = string
}

variable "get_game_lambda_function_name" {
  description = "Name of the get game Lambda function"
  type        = string
}
