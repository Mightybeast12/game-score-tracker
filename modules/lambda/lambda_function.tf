resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.function_name}-dynamodb-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.filename
  output_path = "lambdas/${var.function_name}.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda_exec.arn
  handler         = var.handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}
