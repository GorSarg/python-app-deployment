#!/bin/bash

set -e

echo "Installing Kubernetes setup with Helm"

for cmd in kubectl helm minikube docker; do
    if ! command -v $cmd &>/dev/null; then
        echo "Please install $cmd first!"
        exit 1
    fi
done

if ! kubectl cluster-info &> /dev/null; then
    echo "Kubernetes cluster not accessible. Checking minikube"
    if ! minikube status 2>/dev/null | grep -q "apiserver.*Running"; then
        echo "Starting minikube"
        minikube start
    else
        echo "Minikube is running"
    fi  
    echo "Waiting for cluster to be ready"
    sleep 5
fi

echo "Adding Helm repositories"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || echo "Repository already exists"
helm repo add bitnami https://charts.bitnami.com/bitnami || echo "Repository already exists"
helm repo update

if kubectl get ingressclass nginx &>/dev/null; then
    echo "NGINX Ingress Controller already exists, skipping installation"
else
    echo "Installing NGINX Ingress Controller"
    helm upgrade --install cool-ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --version 4.14.0 -f helm/ingress/values.yaml
fi

echo "Waiting for NGINX Ingress to be ready"
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

echo "Installing MongoDB"
helm upgrade --install cool-mongodb bitnami/mongodb -n mongodb --create-namespace --version 18.1.10 -f helm/mongodb/values.yaml

echo "Waiting for MongoDB to be ready"
kubectl wait --namespace mongodb --for=condition=ready pod --selector=app.kubernetes.io/name=mongodb --timeout=300s

echo "Building API Docker image"
docker build -t cool-api:latest api/ -f api/Dockerfile

if minikube status &>/dev/null; then
    minikube image load cool-api:latest
else
    echo "Not using minikube. Push image to registry and update helm/api/values.yaml"
fi

echo "Installing Python API"
helm upgrade --install cool-api ./helm/api -n api --create-namespace -f helm/api/values.yaml

echo "Waiting for API pods to be ready"
kubectl wait --namespace api --for=condition=ready pod --selector=app.kubernetes.io/name=api --timeout=120s

echo "API ready at http://$(kubectl get ingress cool-api-api -n api -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo 'N/A')"
echo "kubectl port-forward svc/cool-api-api -n api 8080:5000"
echo "http://localhost:8080/health"
echo "MongoDB credentials:"
echo "Username: cool-user"
echo "Password: $(kubectl get secret cool-mongodb -n mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 -d)"