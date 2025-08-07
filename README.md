# 🏆 Dynamic Sports Score Tracker

A serverless sports score tracking application built with AWS Fargate, Lambda, DynamoDB, and API Gateway. Easily configurable for different sports (tennis, football, basketball, etc.).

## Architecture

- **Frontend**: HTML/JS app hosted on Fargate behind ALB
- **Backend**: Lambda functions for game management and scoring
- **Database**: DynamoDB for storing game state and history
- **API**: API Gateway for REST endpoints
- **Dynamic Naming**: All resources use configurable app name prefix

## Features

- ✅ Create new games with player names
- ✅ Real-time score tracking with proper tennis scoring (0, 15, 30, 40)
- ✅ Automatic game, set, and match progression
- ✅ Best of 3 sets format
- ✅ Winner detection and game completion
- ✅ Game history viewing
- ✅ Dynamic sport naming (tennis → football, etc.)

## Default Tennis Scoring Rules

- **Points**: 0, 15, 30, 40, Game
- **Games**: First to 6 games wins set (must win by 2)
- **Sets**: Best of 3 sets wins match

## Deployment

### Prerequisites

- AWS CLI configured
- Docker installed
- Terraform installed

### Quick Deploy

```bash
./deploy.sh
```

This will:
1. Extract app name from terraform.tfvars
2. Build and push the frontend Docker image to ECR
3. Deploy all AWS infrastructure with Terraform
4. Update the frontend with API Gateway URL and app name
5. Force ECS service update

### Change Sport Type

Edit `terraform.tfvars`:
```hcl
app_name = "football"  # Change from "tennis" to any sport
```

Then run `./deploy.sh` - all resources will be renamed automatically.

### Manual Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Build and Push Frontend**:
   ```bash
   APP_NAME=$(grep '^app_name' terraform.tfvars | cut -d'"' -f2)
   cd frontend
   docker build -t ${APP_NAME}-frontend .
   
   # Tag and push to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   docker tag ${APP_NAME}-frontend:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/${APP_NAME}-frontend:latest
   docker push ${APP_NAME}-frontend:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/${APP_NAME}-frontend:latest
   ```

## API Endpoints

- `POST /games` - Create new game
  ```json
  {
    "player1": "John",
    "player2": "Jane"
  }
  ```

- `PUT /games/score` - Update score
  ```json
  {
    "game_id": "uuid",
    "player": "player1"
  }
  ```

- `GET /games/history` - Get game history
  ```json
  {
    "games": []
  }
  ```

## Usage

1. Access the frontend via the ALB DNS name
2. Enter player names and start a new game
3. Click "Score Point" buttons to track the match
4. Game automatically progresses through points, games, and sets
5. Winner is declared when match is complete

## Infrastructure Components

- **VPC**: Custom VPC with public/private subnets and NAT Gateway
- **ALB**: Application Load Balancer for frontend access
- **ECS**: Fargate service running the frontend in private subnets
- **Lambda**: Functions for game logic (create, score, history)
- **DynamoDB**: Game state storage with configurable table name
- **API Gateway**: REST API with CORS support for Lambda functions
- **ECR**: Container registry for frontend image
- **Security Groups**: Proper network isolation

## Dynamic Resource Naming

All resources use the `app_name` variable as prefix:
- DynamoDB: `{app_name}-games`
- Lambda: `{app_name}-create-game`, `{app_name}-score-updater`, etc.
- ECR: `{app_name}-frontend`
- ECS Cluster: `{app_name}-tracker`
- ALB: `{app_name}-tracker-alb`
- API Gateway: `{app_name}-tracker-api`

## Cleanup

```bash
terraform destroy
```

ECR repositories are automatically deleted when `force_delete_ecr = true` in terraform.tfvars.