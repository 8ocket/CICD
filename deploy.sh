#deploy.sh
#!/bin/bash

# 0.git pull
git pull origin main

# 1.AWS 실시간 인프라 정보 확보

# ECR 주소용 계정 ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com"

# RDS 엔드포인트 (test-project-test-db)
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id test-project-test-redis-001 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)

# Redis 엔드포인트 (식별자: test-project-test-redis)
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id test-project-test-redis-001 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)

# Backend LoadBalancer 주소BE_LB_HOST=$(kubectl get svc mindlog-be-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
BE_API_URL="http://${BE_LB_HOST}:8080"

echo "   - ECR: $ECR_URL"
echo "   - RDS: $RDS_ENDPOINT"
echo "   - Redis: $REDIS_ENDPOINT"
echo "   - BE API: $BE_API_URL"

#-----------------------------------------------------------------------------

# 2. 일괄 치환

# AI
sed -i "s|\${ECR_URL}|${ECR_URL}|g" ./ai/deployment.yaml
sed -i "s|\${RDS_ENDPOINT}|${RDS_ENDPOINT}|g" ./ai/deployment.yaml
sed -i "s|\${REDIS_ENDPOINT}|${REDIS_ENDPOINT}|g" ./ai/deployment.yaml

# Backend
sed -i "s|\${ECR_URL}|${ECR_URL}|g" ./backend/deployment.yaml
sed -i "s|\${RDS_ENDPOINT}|${RDS_ENDPOINT}|g" ./backend/deployment.yaml
sed -i "s|\${REDIS_ENDPOINT}|${REDIS_ENDPOINT}|g" ./backend/deployment.yaml

# Frontend
sed -i "s|\${ECR_URL}|${ECR_URL}|g" ./frontend/deployment.yaml
sed -i "s|\${BE_API_URL}|${BE_API_URL}|g" ./frontend/deployment.yaml

#-----------------------------------------------------------------------------

# 3. 쿠버네티스 일괄 배포
kubectl apply -f ./ai/deployment.yaml
kubectl apply -f ./backend/deployment.yaml
kubectl apply -f ./frontend/deployment.yaml

# 변경사항 즉시 반영을 위한 롤아웃 재시작
kubectl rollout restart deployment/mindlog-ai-deployment
kubectl rollout restart deployment/mindlog-be-deployment
kubectl rollout restart deployment/mindlog-fe-deployment

echo "rollout done!"
