# Architecture Explainer

## Overview
This is a serverless sports score tracking application using AWS services. The architecture follows a microservices pattern with clear separation between frontend, API, and data layers.

## File Structure & Purpose

### Root Configuration Files

#### `variables.tf`
- Defines Terraform input variables
- **Key variable**: `app_name` - Controls naming prefix for all resources
- Environment-specific configurations (dev/stg/prod)

#### `terraform.tfvars`
- Sets actual values for variables
- **Change `app_name` here** to switch sports (tennis → football)
- Controls deletion protection and ECR force delete

#### `infrastructure.tf`
- Main Terraform configuration
- Orchestrates all AWS modules
- Uses `${var.app_name}` for dynamic resource naming

#### `deploy.sh`
- Automated deployment script
- Extracts app name from terraform.tfvars
- Builds Docker image, deploys infrastructure, updates frontend

### Frontend (`frontend/`)

#### `index.html`
- Single-page web application
- Uses placeholders: `API_GATEWAY_URL_PLACEHOLDER`, `APP_NAME_PLACEHOLDER`
- Deploy script replaces placeholders with actual values
- Handles game creation, scoring, and history display

#### `Dockerfile`
- Builds nginx container serving the HTML app
- Lightweight container for ECS Fargate

### Lambda Functions (`lambdas/`)

#### `create_game.py`
- **API**: `POST /games`
- **Purpose**: Creates new game in DynamoDB
- **Input**: `{"player1": "John", "player2": "Jane"}`
- **Output**: Game object with UUID and initial scores
- **DynamoDB**: Writes to `{app_name}-games` table

#### `score_updater.py`
- **API**: `PUT /games/score`
- **Purpose**: Updates game score and handles tennis logic
- **Input**: `{"game_id": "uuid", "player": "player1"}`
- **Logic**: Implements tennis scoring (0→15→30→40→game→set→match)
- **DynamoDB**: Updates existing game record
- **Handles**: Decimal serialization for JSON responses

#### `get_history.py`
- **API**: `GET /games/history`
- **Purpose**: Retrieves all games from DynamoDB
- **Output**: List of games with scores and completion status
- **DynamoDB**: Scans `{app_name}-games` table

### Infrastructure Modules (`modules/`)

#### `vpc/networking.tf`
- Creates VPC with public/private subnets
- **NAT Gateway**: Enables private subnet internet access for ECR pulls
- **Route tables**: Proper routing for public/private traffic

#### `dynamodb/dynamodb_table.tf`
- Creates DynamoDB table: `{app_name}-games`
- **Hash key**: `game_id` (UUID)
- **Billing**: Pay-per-request
- **Deletion protection**: Configurable

#### `lambda/lambda_function.tf`
- Creates Lambda functions from Python files
- **Runtime**: Python 3.9
- **Permissions**: DynamoDB read/write access
- **Environment**: Table name passed as env var

#### `api-gateway/api_gateway.tf`
- Creates REST API with three endpoints
- **CORS**: Enabled for browser access
- **Integration**: Lambda proxy integration
- **Deployment**: Auto-deploys to 'prod' stage

#### `ecr/container_registry.tf`
- Creates ECR repository: `{app_name}-frontend`
- **Force delete**: Removes repo even with images
- **Lifecycle**: Keeps only latest 5 images

#### `ecs/` & `frontend/ecs_service.tf`
- **ECS Cluster**: Runs in private subnets
- **Fargate**: Serverless container execution
- **Service**: Maintains desired container count
- **Target Group**: Connects to ALB

#### `alb/load_balancer.tf`
- **Application Load Balancer**: Public-facing
- **Target Group**: Routes to ECS tasks
- **Health Checks**: Ensures container health
- **Security Group**: Allows HTTP/HTTPS traffic

#### `security-groups/security_groups.tf`
- **ALB SG**: Allows internet traffic (80/443)
- **ECS SG**: Allows traffic only from ALB
- **Network isolation**: Follows security best practices

## Data Flow

### Game Creation
1. User enters player names in frontend
2. Frontend calls `POST /games` via API Gateway
3. API Gateway triggers `create_game.py` Lambda
4. Lambda writes to DynamoDB table
5. Returns game_id and initial scores

### Score Updates
1. User clicks "Score Point" button
2. Frontend calls `PUT /games/score` with game_id and player
3. API Gateway triggers `score_updater.py` Lambda
4. Lambda reads current game state from DynamoDB
5. Applies tennis scoring logic
6. Updates DynamoDB with new scores
7. Returns updated game state to frontend

### History Viewing
1. User clicks "View Game History"
2. Frontend calls `GET /games/history`
3. API Gateway triggers `get_history.py` Lambda
4. Lambda scans DynamoDB table
5. Returns all games with scores and status

## Key Design Decisions

### Dynamic Naming
- All resources use `${var.app_name}` prefix
- Enables multiple sport trackers in same AWS account
- Easy rebranding (tennis → football)

### Private Subnets + NAT Gateway
- ECS tasks run in private subnets for security
- NAT Gateway enables ECR image pulls
- ALB in public subnets handles internet traffic

### Lambda + API Gateway
- Serverless backend scales automatically
- Pay-per-request pricing
- CORS enabled for browser access

### DynamoDB Single Table
- Simple key-value storage with game_id as key
- Pay-per-request billing
- No complex relationships needed

### Container Deployment
- Frontend as Docker container for consistency
- ECR for private image storage
- ECS Fargate for serverless container execution

## Customization Points

1. **Sport Type**: Change `app_name` in terraform.tfvars
2. **Scoring Logic**: Modify `score_updater.py` for different sports
3. **Frontend**: Update `index.html` for sport-specific UI
4. **Regions**: Update `aws_region` variable for different deployments
5. **Scaling**: Adjust ECS task count in frontend module