resource "aws_iam_role" "lambda_exec" {
  name = "${var.app_name}-${var.environment}-get-game-role"

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

  tags = {
    Name        = "${var.app_name}-${var.environment}-get-game-role"
    Environment = var.environment
    ManagedBy   = "terraform"
    Application = "game-score-tracker"
    Project     = var.app_name
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.app_name}-${var.environment}-get-game-dynamodb-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Create zip file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambdas/${var.app_name}-${var.environment}-get-game.zip"
  source_file = "lambdas/get_game.py"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.app_name}-${var.environment}-get-game"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "get_game.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-get-game"
    Environment = var.environment
    ManagedBy   = "terraform"
    Application = "game-score-tracker"
    Project     = var.app_name
  }
}
