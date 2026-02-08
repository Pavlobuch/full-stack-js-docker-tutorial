#!/usr/bin/env bash
set -euo pipefail

# ./k8s/images/import-images.sh


kubectl apply -f k8s/namespaces/app.yml
kubectl apply -f k8s/app/limitrange.yml
kubectl apply -f k8s/app/configmap.yml
kubectl apply -f k8s/app/secret.yml
kubectl apply -f k8s/app/mysql-service.yml
kubectl apply -f k8s/app/mysql-statefulset.yml
kubectl apply -f k8s/api/service.yml
kubectl apply -f k8s/api/deployment.yml

kubectl apply -f k8s/ui/service.yml
kubectl apply -f k8s/ui/deployment.yml

kubectl apply -f k8s/nginx/configmap.yml
kubectl apply -f k8s/nginx/service.yml
kubectl apply -f k8s/nginx/deployment.yml


echo "==> Status summary"
kubectl get ns | sed -n '1,8p'
kubectl -n app get pods -o wide
kubectl -n app get svc
kubectl -n app get pvc

