#!/bin/bash

# 1. AWS info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com"

# RDS info
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier rds-prod-8ocket \
  --query 'DBInstances[0].Endpoint.Address' --output text)

# Redis info
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id valkey-prod-8ocket-001 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)

# Backend LoadBalancer 
BE_LB_HOST=$(kubectl get svc mindlog-be-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
BE_API_URL="http://${BE_LB_HOST}:8080"

echo "   - ECR: $ECR_URL"
echo "   - RDS: $RDS_ENDPOINT"
echo "   - Redis: $REDIS_ENDPOINT"
echo "   - BE API: $BE_API_URL"

# -----------------------------------------------------------------------------

# 2. Kubernetes Secret 
kubectl delete secret mindlog-be-secret --ignore-not-found
kubectl create secret generic mindlog-be-secret \
  --from-literal=DB_PASSWORD='test1234' \
  --from-literal=KT_JWT_SECRET='mindlog_jwt_secret' \
  --from-literal=DB_DEV_HOST="$RDS_ENDPOINT" \
  --from-literal=REDIS_DEV_HOST="$REDIS_ENDPOINT"

# -----------------------------------------------------------------------------

# 3. YAML 파일 수정
sed -i "s|image: .*mindlog-be:latest|image: ${ECR_URL}/mindlog-be:latest|g" ./backend/deployment.yaml
sed -i "s|image: .*mindlog-ai:latest|image: ${ECR_URL}/mindlog-ai:latest|g" ./ai/deployment.yaml
sed -i "s|value: \"http://.*:8080\"|value: \"${BE_API_URL}\"|g" ./frontend/deployment.yaml

# -----------------------------------------------------------------------------

echo "done!"
