#!/bin/bash

# 1. AWS info
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_IMAGE_URL="${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/mindlog-be:latest"

export RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier rds-prod-8ocket \
  --query 'DBInstances[0].Endpoint.Address' --output text)

export REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
  --replication-group-id valkey-prod-8ocket \
  --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address' --output text)

# BE lb
BE_LB_HOST=$(kubectl get svc mindlog-be-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export BE_API_URL="http://${BE_LB_HOST}:8080"

echo "------------------------------------------"
echo "   - ECR Image: $ECR_IMAGE_URL"
echo "   - RDS Endpoint: $RDS_ENDPOINT"
echo "   - Redis: $REDIS_ENDPOINT"
echo "   - BE API: $BE_API_URL"
echo "------------------------------------------"

# 2. Kubernetes Secret 
# (시크릿 키 이름들을 YAML에서 참조하는 이름과 일치시켰습니다)
kubectl delete secret mindlog-be-secret -n default --ignore-not-found
kubectl create secret generic mindlog-be-secret -n default \
  --from-literal=DB_USERNAME="mindlog" \
  --from-literal=DB_PASSWORD='mindlog_password' \
  --from-literal=DB_NAME='mindlog_db' \
  --from-literal=KT_JWT_SECRET='kt-cloud-8ocket-mindLog-jwt-secret-key' \
  --from-literal=DB_DEV_HOST="$RDS_ENDPOINT" \
  --from-literal=REDIS_DEV_HOST="$REDIS_ENDPOINT"


# be sync
sed -i "s|\${ECR_IMAGE_URL}|$ECR_IMAGE_URL|g" ./backend/deployment.yaml
sed -i "s|\${RDS_ENDPOINT}|$RDS_ENDPOINT|g" ./backend/deployment.yaml

# fe sync
if [ -f "./frontend/deployment.yaml" ]; then
    sed -i "s|\${BE_API_URL}|$BE_API_URL|g" ./frontend/deployment.yaml
fi

# 4. Git push
git add .
git commit -m "chore: auto-deploy - infrastructure sync [$(date +'%Y-%m-%d %H:%M:%S')]"
git push origin main

echo "------------------------------------------"
echo "done!"
