variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "deletion_protection" {
  description = "Enable deletion protection for DynamoDB table"
  type        = bool
  default     = false
}

output "table_name" {
  value = aws_dynamodb_table.this.name
}

output "table_arn" {
  value = aws_dynamodb_table.this.arn
}