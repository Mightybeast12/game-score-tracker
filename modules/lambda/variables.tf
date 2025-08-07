variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "filename" {
  description = "Path to the Lambda function source file"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}