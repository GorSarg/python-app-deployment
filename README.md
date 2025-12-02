# Python API on Kubernetes

Flask API with MongoDB and NGINX Ingress deployed on minikube using Helm.

> **⚠️ Development Only**: This setup is for development/testing purposes only. For production use, implement MongoDB persistence, secure secret management (e.g., Vault, AWS Secrets Manager), TLS encryption, and proper authentication.

## Prerequisites

- minikube
- kubectl
- Helm 3.x
- Docker

## Quick Start

**For minikube:**
```bash
./install.sh
```

**For real Kubernetes clusters:**
1. Push the image to a container registry:
   ```bash
   docker build -t <your-registry>/cool-api:latest api/
   docker push <your-registry>/cool-api:latest
   ```
2. Update `helm/api/values.yaml` with your registry:
   ```yaml
   image:
     repository: <your-registry>/cool-api
     tag: latest
   ```
3. Run the install script (it will skip minikube image loading)

The script will:
- Verify required tools are installed
- Start minikube if not running
- Install NGINX Ingress Controller (if ingressclass does not exist) (v4.14.0)
- Install MongoDB (v18.1.10)
- Build and deploy the Pretty Cool Flask API

## Access the API

```bash
kubectl port-forward svc/cool-api-api -n api 8080:5000
```

Visit: http://localhost:8080/health

**Endpoints:**
- `GET /health` - Health check with MongoDB connection status

## Project Structure

```
.
├── api/
│   ├── app.py              # Flask application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Container image
├── helm/
│   ├── api/                # API Helm chart
│   ├── mongodb/            # MongoDB values
│   └── ingress/            # Ingress values
└── install.sh              # Installation script
```

## Configuration

**MongoDB Connection:**
- URI: Set via `MONGODB_URI` environment variable
- Default: `mongodb://localhost:27017`

**API Port:**
- Set via `PORT` environment variable
- Default: `5000`

## Get MongoDB Credentials

```bash
kubectl get secret cool-mongodb -n mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 -d
```

## Cleanup

```bash
helm uninstall cool-api -n api
helm uninstall cool-mongodb -n mongodb
helm uninstall cool-ingress-nginx -n ingress-nginx
```

Or delete the entire cluster:
```bash
minikube delete
```


