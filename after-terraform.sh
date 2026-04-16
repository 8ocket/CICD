aws eks update-kubeconfig --region ap-northeast-2 --name mindlog
kubectl apply -f ~/cicd/applications.yaml -n argocd
./deploy.sh

# New Relic 
helm repo add newrelic https://helm-charts.newrelic.com
helm repo update
helm upgrade --install newrelic newrelic/nri-bundle \
  --namespace newrelic --create-namespace \
  -f ~/cicd/newrelic/values.yaml
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=newrelic-k8s-agents-operator -n newrelic --timeout=300s
kubectl apply -f ~/cicd/newrelic/instrumentation.yaml -n newrelic
kubectl get pods -n newrelic
