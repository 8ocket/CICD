#!/bin/bash

# 1. AWS 및 인프라 정보 자동 추출
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_URL="${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com"

export RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier rds-prod-8ocket \
  --query 'DBInstances[0].Endpoint.Address' --output text)

export REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
  --replication-group-id valkey-prod-8ocket \
  --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address' --output text)

# BE 로드밸런서 주소 추출
BE_LB_HOST=$(kubectl get svc mindlog-be-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export BE_API_URL="http://${BE_LB_HOST}:8080"

echo "------------------------------------------"
echo "   - ECR: $ECR_URL"
echo "   - RDS: $RDS_ENDPOINT"
echo "   - Redis: $REDIS_ENDPOINT"
echo "   - BE API: $BE_API_URL"
echo "------------------------------------------"

# 2. Kubernetes Secret 재생성 (default 네임스페이스 명시)
kubectl delete secret mindlog-be-secret -n defaulmindlog_passwordt --ignore-not-found
kubectl create secret generic mindlog-be-secret -n default \
  --from-literal=DB_USERNAME="mindlog" \
  --from-literal=DB_PASSWORD='mindlog_password' \
  --from-literal=KT_JWT_SECRET='kt-cloud-8ocket-mindLog-jwt-secret-key' \
  --from-literal=DB_DEV_HOST="$RDS_ENDPOINT" \
  --from-literal=REDIS_DEV_HOST="$REDIS_ENDPOINT"

# 3. YAML 파일 내용 강제 치환 (변수명 자체를 타겟팅)

# ECR 주소 치환 (${ECR_URL} 문자열 자체를 바꿈)
find . -name "deployment.yaml" -exec sed -i "s|\${ECR_URL}|$ECR_URL|g" {} +

# FE의 BE_API_URL 치환 (${BE_API_URL} 문자열 자체를 바꿈)
sed -i "s|\${BE_API_URL}|$BE_API_URL|g" ./frontend/deployment.yaml

# 4. Git push
git add .
git commit -m "chore: auto-deploy - infrastructure sync [$(date +'%Y-%m-%d %H:%M:%S')]"
git push origin main

# 5. ArgoCD sync
argocd app sync mindlog-ai --prune --force
argocd app sync mindlog-backend --prune --force
argocd app sync mindlog-frontend --prune --force

echo "------------------------------------------"
echo "done!"
