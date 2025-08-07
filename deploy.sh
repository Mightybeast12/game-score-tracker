#!/bin/bash

echo "🏆 Deploying Score Tracker..."

# Get AWS account ID, region, and app name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
APP_NAME=$(grep '^app_name' terraform.tfvars | cut -d'"' -f2)
ENVIRONMENT="dev"  # Default environment
ECR_REPO_NAME="${APP_NAME}-${ENVIRONMENT}-frontend"
ECS_CLUSTER_NAME="${APP_NAME}-tracker"
ECS_SERVICE_NAME="${APP_NAME}-frontend"

# Deploy infrastructure first
echo "Deploying infrastructure..."
terraform init
terraform plan
terraform apply -auto-approve

# Build and push frontend Docker image
cd frontend
docker build -t ${APP_NAME}-frontend .

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag and push image
docker tag ${APP_NAME}-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${ECR_REPO_NAME}:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${ECR_REPO_NAME}:latest

cd ..

# Get API Gateway URL and update frontend
API_URL=$(terraform output -raw api_gateway_url)
echo "Updating frontend with API URL: $API_URL and App Name: $APP_NAME"

# Create a fresh copy from template and update it
cp frontend/index.html frontend/index.html.bak 2>/dev/null || true
sed "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g; s|APP_NAME_PLACEHOLDER|$(echo $APP_NAME | sed 's/^./\U&/')|g" frontend/index.html > frontend/index.html.tmp
mv frontend/index.html.tmp frontend/index.html

# Rebuild and push updated frontend
cd frontend
docker build -t ${APP_NAME}-frontend .
docker tag ${APP_NAME}-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${ECR_REPO_NAME}:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${ECR_REPO_NAME}:latest
cd ..

# Force ECS service update
aws ecs update-service --cluster ${APP_NAME}-tracker --service ${APP_NAME}-frontend --force-new-deployment 2>/dev/null || true

# Restore template for next deployment
if [ -f frontend/index.html.bak ]; then
    mv frontend/index.html.bak frontend/index.html
fi

echo "✅ Deployment complete!"
echo "Frontend URL: http://$(terraform output -raw alb_dns_name)"
echo "API URL: $(terraform output -raw api_gateway_url)"
