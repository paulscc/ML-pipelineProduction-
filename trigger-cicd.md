# CI/CD Pipeline Trigger

This file triggers the CI/CD pipeline with all secrets configured.

## Status
- ✅ Environment configured
- ✅ Secrets configured in GitHub
- ✅ Ready for deployment

## Pipeline Components
- Testing: Unit tests, linting, security scanning
- Build: Docker images for all services
- Deploy: Kubernetes deployment to Minikube local

## Services
- Web UI: http://localhost:5000
- Inference API: http://localhost:5001
- Kafka UI: http://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
