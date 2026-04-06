#!/bin/bash

# 1. AWS info
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier rds-prod-8ocket \
  --query 'DBInstances[0].Endpoint.Address' --output text)

export REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
  --replication-group-id valkey-prod-8ocket \
  --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address' --output text)

# BE lb host
BE_LB_HOST=$(kubectl get svc mindlog-be-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export BE_API_URL="http://${BE_LB_HOST}:8080"

echo "------------------------------------------"
echo "   - Account ID: $ACCOUNT_ID"
echo "   - RDS: $RDS_ENDPOINT"
echo "   - Redis: $REDIS_ENDPOINT"
echo "   - BE API: $BE_API_URL"
echo "------------------------------------------"

# 2. setup secret 
chmod +x ./setup-secrets.sh
./setup-secrets.sh

# 3. Template -> YAML Sync

# BE Sync
sed -e "s|\${ACCOUNT_ID}|$ACCOUNT_ID|g" \
    -e "s|\${RDS_ENDPOINT}|$RDS_ENDPOINT|g" \
    -e "s|\${REDIS_ENDPOINT}|$REDIS_ENDPOINT|g" ./backend/deployment.yaml.template > ./backend/deployment.yaml

# AI Sync
sed -e "s|\${ACCOUNT_ID}|$ACCOUNT_ID|g" \
    -e "s|\${RDS_ENDPOINT}|$RDS_ENDPOINT|g" \
    -e "s|\${REDIS_ENDPOINT}|$REDIS_ENDPOINT|g" ./ai/deployment.yaml.template > ./ai/deployment.yaml

# FE Sync
sed -e "s|\${ACCOUNT_ID}|$ACCOUNT_ID|g" \
    -e "s|\${BE_API_URL}|$BE_API_URL|g" ./frontend/deployment.yaml.template > ./frontend/deployment.yaml

# 4. Git Push 
git add .
git commit -m "chore: infrastructure sync [$(date +'%Y-%m-%d %H:%M:%S')]"
git push origin main

# 5. Cleanup 
kubectl delete pods --field-selector status.phase=Pending

echo "------------------------------------------"
echo "Git Push Done! ArgoCD will sync automatically."
echo "------------------------------------------"
