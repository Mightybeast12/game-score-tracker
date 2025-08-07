# VPC and networking
module "vpc" {
  source      = "./modules/vpc"
  name        = "${var.app_name}-${var.environment}"
  common_tags = local.common_tags
}

# DynamoDB
module "dynamodb" {
  source                        = "./modules/dynamodb"
  table_name                    = "${var.app_name}-${var.environment}-games"
  deletion_protection           = var.destroy_mode ? false : var.enable_deletion_protection
  enable_point_in_time_recovery = var.destroy_mode ? false : var.enable_point_in_time_recovery
  common_tags                   = local.common_tags
}

# Lambda functions
module "create_game_lambda" {
  source        = "./modules/lambda-create-game"
  function_name = "${var.app_name}-${var.environment}-create-game"
  filename      = "lambdas/create_game.py"
  handler       = "create_game.lambda_handler"
  runtime       = var.lambda_runtime
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
  common_tags   = local.common_tags
}

module "score_updater_lambda" {
  source        = "./modules/lambda-score-updater"
  function_name = "${var.app_name}-${var.environment}-score-updater"
  filename      = "lambdas/score_updater.py"
  handler       = "score_updater.lambda_handler"
  runtime       = var.lambda_runtime
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
  common_tags   = local.common_tags
}

module "get_history_lambda" {
  source        = "./modules/lambda-get-history"
  function_name = "${var.app_name}-${var.environment}-get-history"
  filename      = "lambdas/get_history.py"
  handler       = "get_history.lambda_handler"
  runtime       = var.lambda_runtime
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
  common_tags   = local.common_tags
}

module "get_game_lambda" {
  source = "./modules/lambda-get-game"

  app_name            = var.app_name
  environment         = var.environment
  dynamodb_table_arn  = module.dynamodb.table_arn
  dynamodb_table_name = module.dynamodb.table_name
}

# ECR
module "ecr" {
  source          = "./modules/ecr"
  repository_name = "${var.app_name}-${var.environment}-frontend"
  force_delete    = var.force_delete_ecr
  common_tags     = local.common_tags
}

# ALB
module "alb" {
  source      = "./modules/alb"
  name        = "${var.app_name}-${var.environment}-alb"
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.public_subnet_ids
  common_tags = local.common_tags
}

# Security Groups
module "security_groups" {
  source                = "./modules/security-groups"
  name_prefix           = var.app_name
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.alb_security_group_id
}

# Frontend
module "frontend" {
  source             = "./modules/frontend"
  name               = "${var.app_name}-frontend"
  cluster_name       = "${var.app_name}-tracker"
  image_uri          = "${module.ecr.repository_url}:latest"
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.ecs_security_group_id
  target_group_arn   = module.alb.target_group_arn
  alb_listener_arn   = module.alb.listener_arn
}

# API Gateway
module "api_gateway" {
  source                             = "./modules/api-gateway"
  api_name                           = "${var.app_name}-${var.environment}-api"
  create_game_lambda_invoke_arn      = module.create_game_lambda.invoke_arn
  create_game_lambda_function_name   = module.create_game_lambda.function_name
  score_updater_lambda_invoke_arn    = module.score_updater_lambda.invoke_arn
  score_updater_lambda_function_name = module.score_updater_lambda.function_name
  get_history_lambda_invoke_arn      = module.get_history_lambda.invoke_arn
  get_history_lambda_function_name   = module.get_history_lambda.function_name
  get_game_lambda_invoke_arn         = module.get_game_lambda.invoke_arn
  get_game_lambda_function_name      = module.get_game_lambda.function_name
}
