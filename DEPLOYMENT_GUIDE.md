# 🚀 ML Engagement Prediction System - Deployment Guide

## Table of Contents
1. [System Overview](#system-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Local Development](#local-development)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Monitoring & Observability](#monitoring--observability)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance](#maintenance)

## System Overview

This is a complete MLOps system for user engagement prediction with the following components:

### 🎯 Core Components
- **Training Service**: Automated model training with W&B tracking
- **Inference Service**: REST API for real-time predictions
- **Web UI**: Interactive dashboard for predictions and analytics
- **Kafka Integration**: Real-time data streaming and batch processing
- **Monitoring Stack**: Prometheus + Grafana for system metrics
- **ML Tracking**: Weights & Biases for experiment tracking

### 🏗️ Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web UI        │    │  Inference      │    │   Training      │
│   (Flask)       │◄──►│  Service        │◄──►│   Service       │
│   Port: 5000    │    │  Port: 5001     │    │   CronJob       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │   Weights &     │              │
         └──────────────►│   Biases        │◄─────────────┘
                        │   Tracking      │
                        └─────────────────┘
                                 │
         ┌─────────────────┐    │    ┌─────────────────┐
         │   Grafana       │◄───┼───►│   Prometheus    │
         │   Port: 3000    │    │    │   Port: 9090    │
         └─────────────────┘    │    └─────────────────┘
                                 │
         ┌─────────────────┐    │
         │   Apache Kafka  │◄───┘
         │   Port: 9092    │
         └─────────────────┘
```

## Prerequisites

### 📋 Required Software
- **Docker**: >= 20.10.0
- **Kubernetes**: >= 1.24.0
- **kubectl**: >= 1.24.0
- **Python**: >= 3.9
- **Node.js**: >= 16 (for some development tools)

### 🔑 Required Accounts
- **Docker Hub**: For container registry
- **Weights & Biases**: For ML experiment tracking
- **GitHub**: For CI/CD pipeline
- **Cloud Provider**: GCP, AWS, or Azure for Kubernetes cluster

### 🌐 Environment Variables
Create a `.env` file:
```bash
# W&B Configuration
WANDB_API_KEY=your_wandb_api_key
WANDB_PROJECT=mlip-engagement-prediction

# Docker Configuration
DOCKER_REGISTRY=your-docker-username
DOCKER_TAG=latest

# Kubernetes Configuration
KUBE_CONFIG_PATH=path/to/kubeconfig
NAMESPACE=mlip-system

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
GRAFANA_URL=http://grafana:3000

# Kafka
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
```

## Quick Start

### 1️⃣ Clone and Setup
```bash
git clone https://github.com/your-org/mlip-engagement-prediction.git
cd mlip-engagement-prediction

# Copy environment template
cp .env.example .env
# Edit .env with your credentials
```

### 2️⃣ Local Development with Docker Compose
```bash
# Start all services locally
docker-compose -f docker-compose.kafka.yaml up -d

# Check service status
docker-compose -f docker-compose.kafka.yaml ps

# View logs
docker-compose -f docker-compose.kafka.yaml logs -f
```

### 3️⃣ Access Services
- **Web UI**: http://localhost:5000
- **Inference API**: http://localhost:5001
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Kafka UI**: http://localhost:8080

### 4️⃣ Test the System
```bash
# Test prediction endpoint
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "avg_session_duration": 25.5,
    "visits_per_week": 8,
    "response_rate": 75.0,
    "feature_usage_depth": 6
  }'

# Run integration tests
python tests/integration_test.py \
  --web-ui-url http://localhost:5000 \
  --inference-url http://localhost:5001
```

## Local Development

### 🐳 Docker Development
```bash
# Build individual services
docker build -f Dockerfile.trainer.enhanced -t mlip/trainer .
docker build -f Dockerfile.backend.enhanced -t mlip/inference .
docker build -f Dockerfile.web -t mlip/web-ui .
docker build -f Dockerfile.kafka -t mlip/kafka-processor .

# Run with development overrides
docker-compose -f docker-compose.kafka.yaml -f docker-compose.dev.yaml up
```

### 🧪 Testing
```bash
# Unit tests
pytest tests/unit/ -v

# Integration tests
pytest tests/integration/ -v

# Performance tests
k6 run tests/performance_test.js

# Code quality
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
black --check .
isort --check-only .
mypy . --ignore-missing-imports
```

### 📊 Local Monitoring
```bash
# Start Prometheus and Grafana
docker-compose -f monitoring/docker-compose.monitoring.yaml up -d

# Import Grafana dashboards
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @monitoring/grafana/dashboards/ml-system-dashboard.json
```

## Kubernetes Deployment

### 🚀 Cluster Setup
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply configurations
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml

# Deploy Kafka infrastructure
kubectl apply -f k8s/kafka-deployment.yaml

# Wait for Kafka to be ready
kubectl wait --for=condition=ready pod -l app=kafka -n mlip-system --timeout=300s
```

### 📦 Deploy Applications
```bash
# Deploy core services
kubectl apply -f k8s/inference-deployment.yaml
kubectl apply -f k8s/web-ui-deployment.yaml
kubectl apply -f k8s/monitoring-deployment.yaml

# Deploy training job
kubectl apply -f k8s/training-cronjob.yaml

# Deploy ingress
kubectl apply -f k8s/ingress.yaml

# Check deployment status
kubectl get pods -n mlip-system
kubectl get services -n mlip-system
kubectl get ingress -n mlip-system
```

### 🔍 Verify Deployment
```bash
# Check pod health
kubectl get pods -n mlip-system -w

# Check service endpoints
kubectl get endpoints -n mlip-system

# Port forward for local testing
kubectl port-forward service/web-ui-service 5000:5000 -n mlip-system
kubectl port-forward service/inference-service 5001:5001 -n mlip-system
kubectl port-forward service/grafana-service 3000:3000 -n mlip-system
```

### 📈 Scaling
```bash
# Scale inference service
kubectl scale deployment inference-deployment --replicas=5 -n mlip-system

# Check HPA status
kubectl get hpa -n mlip-system

# View autoscaling events
kubectl describe hpa inference-hpa -n mlip-system
```

## Monitoring & Observability

### 📊 Prometheus Metrics
Key metrics to monitor:
- `http_requests_total`: HTTP request count
- `http_request_duration_seconds`: Request latency
- `predictions_total`: Total predictions made
- `model_load_time_seconds`: Model load timestamp
- `active_connections`: Active connections

### 📈 Grafana Dashboards
1. **System Dashboard**: CPU, Memory, Network
2. **ML Dashboard**: Model performance, predictions
3. **Kafka Dashboard**: Message throughput, lag
4. **Business Dashboard**: User engagement metrics

### 🔔 Alerting
```yaml
# Example alert rules
groups:
- name: ml-system-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      
  - alert: ModelNotLoaded
    expr: model_load_time_seconds == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Model is not loaded"
```

### 📋 W&B Integration
```bash
# Login to W&B
wandb login

# View experiments
wandb dashboard

# Sync local runs
wandb sync
```

## Troubleshooting

### 🔧 Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n mlip-system -o wide

# Describe pod issues
kubectl describe pod <pod-name> -n mlip-system

# View pod logs
kubectl logs <pod-name> -n mlip-system --tail=50

# Check events
kubectl get events -n mlip-system --sort-by=.metadata.creationTimestamp
```

#### 2. Service Connection Issues
```bash
# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
# Inside pod:
# nslookup inference-service.mlip-system
# wget -qO- http://inference-service.mlip-system:5001/health

# Check service endpoints
kubectl get endpoints inference-service -n mlip-system

# Check network policies
kubectl get networkpolicies -n mlip-system
```

#### 3. Kafka Issues
```bash
# Check Kafka broker status
kubectl exec kafka-0 -n mlip-system -- kafka-broker-api-versions --bootstrap-server localhost:9092

# List topics
kubectl exec kafka-0 -n mlip-system -- kafka-topics --bootstrap-server localhost:9092 --list

# Check consumer groups
kubectl exec kafka-0 -n mlip-system -- kafka-consumer-groups --bootstrap-server localhost:9092 --list
```

#### 4. Model Loading Issues
```bash
# Check model storage
kubectl exec -it inference-deployment-xxx -n mlip-system -- ls -la /shared-volume/

# Check model file
kubectl exec -it inference-deployment-xxx -n mlip-system -- python -c "import joblib; print(joblib.load('/shared-volume/model.joblib'))"

# Trigger manual model reload
kubectl exec -it inference-deployment-xxx -n mlip-system -- curl -X POST http://localhost:5001/reload-model
```

#### 5. W&B Connection Issues
```bash
# Check W&B configuration
kubectl exec -it inference-deployment-xxx -n mlip-system -- env | grep WANDB

# Test W&B connection
kubectl exec -it inference-deployment-xxx -n mlip-system -- python -c "import wandb; print(wandb.api.api_url())"

# Check W&B runs
kubectl exec -it inference-deployment-xxx -n mlip-system -- python -c "import wandb; api = wandb.Api(); print(len(api.runs('mlip-engagement-prediction')))"
```

### 🚨 Emergency Procedures

#### 1. System Recovery
```bash
# Restart all deployments
kubectl rollout restart deployment/inference-deployment -n mlip-system
kubectl rollout restart deployment/web-ui-deployment -n mlip-system
kubectl rollout restart deployment/grafana -n mlip-system

# Force redeploy
kubectl delete deployment inference-deployment -n mlip-system --force --grace-period=0
kubectl apply -f k8s/inference-deployment.yaml
```

#### 2. Data Recovery
```bash
# Backup persistent volumes
kubectl get pvc -n mlip-system
kubectl cp namespace/pvc-name:/path backup/

# Restore from backup
kubectl cp backup/ namespace/pvc-name:/path
```

#### 3. Rollback
```bash
# Check rollout history
kubectl rollout history deployment/inference-deployment -n mlip-system

# Rollback to previous version
kubectl rollout undo deployment/inference-deployment -n mlip-system --to-revision=2
```

## Maintenance

### 🔄 Regular Tasks

#### Daily
- Check system health: `kubectl get pods -n mlip-system`
- Review metrics in Grafana
- Check W&B experiment runs

#### Weekly
- Update container images
- Review and rotate secrets
- Backup configurations and data
- Performance testing

#### Monthly
- Kubernetes version updates
- Dependency updates
- Security patches
- Capacity planning

### 📊 Performance Tuning

#### Resource Optimization
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods -n mlip-system

# Adjust resource limits
kubectl edit deployment inference-deployment -n mlip-system

# Optimize HPA settings
kubectl edit hpa inference-hpa -n mlip-system
```

#### Database Optimization
```bash
# Compaction (if using persistent storage)
kubectl exec kafka-0 -n mlip-system -- kafka-configs --bootstrap-server localhost:9092 --entity-type topics --entity-name user-events --alter --add-config retention.ms=604800000
```

### 🛡️ Security

#### Regular Security Checks
```bash
# Scan images for vulnerabilities
trivy image mlip/inference:latest

# Check RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:mlip-system:default

# Review network policies
kubectl get networkpolicies -n mlip-system -o yaml
```

#### Secret Rotation
```bash
# Update secrets
kubectl create secret generic mlip-secrets --from-literal=WANDB_API_KEY=new_key --dry-run=client -o yaml | kubectl apply -f -

# Restart services to pick up new secrets
kubectl rollout restart deployment/inference-deployment -n mlip-system
```

### 📚 Documentation Updates
- Update API documentation
- Maintain runbooks
- Update architecture diagrams
- Document incident responses

## 🆘 Support

### 📞 Getting Help
1. Check this guide first
2. Review logs and metrics
3. Check GitHub Issues
4. Contact the ML team

### 🐛 Bug Reporting
1. Include system information
2. Provide reproduction steps
3. Attach relevant logs
4. Include metrics snapshots

### 📈 Feature Requests
1. Submit GitHub Issues with "enhancement" label
2. Provide use case details
3. Include acceptance criteria
4. Consider contributing

---

## 🎉 Success Criteria

Your deployment is successful when:
- ✅ All pods are running and healthy
- ✅ Web UI is accessible and functional
- ✅ Inference API responds correctly
- ✅ Kafka is processing messages
- ✅ Monitoring dashboards show data
- ✅ Training jobs run successfully
- ✅ Load balancing works across pods
- ✅ Autoscaling responds to load
- ✅ W&B tracking is active
- ✅ Integration tests pass

Happy deploying! 🚀
