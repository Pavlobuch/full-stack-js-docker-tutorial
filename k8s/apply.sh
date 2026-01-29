#!/usr/bin/env bash
set -euo pipefail

./k8s/images/import-images.sh


kubectl apply -f k8s/namespaces/app.yml
kubectl apply -f k8s/app/configmap.yml
kubectl apply -f k8s/app/secret.yml
kubectl apply -f k8s/app/mysql-service.yml
kubectl apply -f k8s/app/mysql-statefulset.yml
kubectl apply -f k8s/api/service.yml
kubectl apply -f k8s/api/deployment.yml


kubectl get ns
kubectl get all -n app
kubectl get pvc -n app
