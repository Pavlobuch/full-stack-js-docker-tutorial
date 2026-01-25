#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f k8s/namespaces/app.yml
kubectl apply -f k8s/app/configmap.yml
kubectl apply -f k8s/app/secret.yml
kubectl apply -f k8s/app/mysql-service.yml
kubectl apply -f k8s/app/mysql-statefulset.yml

kubectl get ns
kubectl get all -n app
kubectl get pvc -n app
