#!/bin/bash

# 1. AWS 및 인프라 정보 자동 추출
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_URL="${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com"

export RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier rds-prod-8ocket \
  --query 'DBInstances[0].Endpoint.Address' --output text)

export REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id valkey-prod-8ocket-001 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)

# BE 로드밸런서 주소 추출
BE_LB_HOST=$(kubectl get svc mindlog-be-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export BE_API_URL="http://${BE_LB_HOST}:8080"

echo "------------------------------------------"
echo "🔍 추출된 인프라 정보:"
echo "   - ECR: $ECR_URL"
echo "   - RDS: $RDS_ENDPOINT"
echo "   - Redis: $REDIS_ENDPOINT"
echo "   - BE API: $BE_API_URL"
echo "------------------------------------------"

# 2. Kubernetes Secret 재생성 (default 네임스페이스 명시)
echo "🔐 시크릿 재생성 중..."
kubectl delete secret mindlog-be-secret -n default --ignore-not-found
kubectl create secret generic mindlog-be-secret -n default \
  --from-literal=DB_PASSWORD='test1234' \
  --from-literal=KT_JWT_SECRET='kt-cloud-8ocket-mindLog-jwt-secret-key' \
  --from-literal=DB_DEV_HOST="$RDS_ENDPOINT" \
  --from-literal=REDIS_DEV_HOST="$REDIS_ENDPOINT"

# 3. YAML 파일 내용 강제 치환 (변수명 자체를 타겟팅)
echo "📝 YAML 파일 수정 중..."

# ECR 주소 치환 (${ECR_URL} 문자열 자체를 바꿈)
find . -name "deployment.yaml" -exec sed -i "s|\${ECR_URL}|$ECR_URL|g" {} +

# FE의 BE_API_URL 치환 (${BE_API_URL} 문자열 자체를 바꿈)
sed -i "s|\${BE_API_URL}|$BE_API_URL|g" ./frontend/deployment.yaml

# 4. Git 반영 (이게 없으면 ArgoCD가 안 바뀝니다!)
echo "📦 GitHub에 변경사항 반영 중..."
git add .
git commit -m "chore: auto-deploy - infrastructure sync [$(date +'%Y-%m-%d %H:%M:%S')]"
git push origin main

# 5. ArgoCD 강제 동기화 (기다리기 답답하니까 바로 실행)
echo "🔄 ArgoCD 동기화 중..."
argocd app sync mindlog-ai --prune --force
argocd app sync mindlog-backend --prune --force
argocd app sync mindlog-frontend --prune --force

echo "------------------------------------------"
echo "✅ 배포 명령 완료! kubectl get pod -n default -w 로 확인하세요."
echo "------------------------------------------"
