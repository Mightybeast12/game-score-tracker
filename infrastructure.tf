# VPC and networking
module "vpc" {
  source = "./modules/vpc"
  name   = "${var.app_name}-tracker"
}

# DynamoDB
module "dynamodb" {
  source              = "./modules/dynamodb"
  table_name          = "${var.app_name}-games"
  deletion_protection = var.enable_deletion_protection
}

# Lambda functions
module "create_game_lambda" {
  source        = "./modules/lambda"
  function_name = "${var.app_name}-create-game"
  filename      = "lambdas/create_game.py"
  handler       = "create_game.lambda_handler"
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
}

module "score_updater_lambda" {
  source        = "./modules/lambda"
  function_name = "${var.app_name}-score-updater"
  filename      = "lambdas/score_updater.py"
  handler       = "score_updater.lambda_handler"
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
}

module "get_history_lambda" {
  source        = "./modules/lambda"
  function_name = "${var.app_name}-get-history"
  filename      = "lambdas/get_history.py"
  handler       = "get_history.lambda_handler"
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
}

# ECR
module "ecr" {
  source          = "./modules/ecr"
  repository_name = "${var.app_name}-frontend"
  force_delete    = var.force_delete_ecr
}

# ALB
module "alb" {
  source  = "./modules/alb"
  name    = "${var.app_name}-tracker-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids
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
  api_name                           = "${var.app_name}-tracker-api"
  create_game_lambda_invoke_arn      = module.create_game_lambda.invoke_arn
  create_game_lambda_function_name   = module.create_game_lambda.function_name
  score_updater_lambda_invoke_arn    = module.score_updater_lambda.invoke_arn
  score_updater_lambda_function_name = module.score_updater_lambda.function_name
  get_history_lambda_invoke_arn      = module.get_history_lambda.invoke_arn
  get_history_lambda_function_name   = module.get_history_lambda.function_name
}