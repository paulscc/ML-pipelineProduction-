#!/bin/bash

# ML Engagement Prediction System - Deployment Script
# This script handles deployment to different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
load_env() {
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_success "Environment variables loaded"
    else
        print_error ".env file not found. Please run setup.sh first."
        exit 1
    fi
}

# Deploy to local Docker environment
deploy_local() {
    print_status "Deploying to local Docker environment..."
    
    # Navigate to the correct directory
    if [ ! -f "docker-compose.kafka.yaml" ]; then
        cd mlip-kubernetes-lab
    fi
    
    # Stop existing services
    docker-compose -f docker-compose.kafka.yaml down
    
    # Start services
    docker-compose -f docker-compose.kafka.yaml up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Health checks
    local services_healthy=true
    
    if ! curl -f http://localhost:5000/health &>/dev/null; then
        print_warning "Web UI not healthy"
        services_healthy=false
    fi
    
    if ! curl -f http://localhost:5001/health &>/dev/null; then
        print_warning "Inference service not healthy"
        services_healthy=false
    fi
    
    if ! curl -f http://localhost:3000/api/health &>/dev/null; then
        print_warning "Grafana not healthy"
        services_healthy=false
    fi
    
    if [ "$services_healthy" = true ]; then
        print_success "All services are healthy"
    else
        print_warning "Some services may still be starting up"
    fi
    
    print_success "Local deployment completed"
    show_local_urls
}

show_local_urls() {
    echo
    echo -e "${BLUE}=== Local Service URLs ===${NC}"
    echo "Web UI:        http://localhost:5000"
    echo "Inference API: http://localhost:5001"
    echo "Grafana:       http://localhost:3000 (admin/admin)"
    echo "Prometheus:    http://localhost:9090"
    echo "Kafka UI:      http://localhost:8080"
    echo
}

# Deploy to Kubernetes
deploy_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Navigate to the correct directory
    if [ ! -d "k8s" ]; then
        cd mlip-kubernetes-lab
    fi
    
    # Apply namespace and configurations
    print_status "Applying namespace and configurations..."
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    
    # Apply secrets (if configured)
    if [ -f "k8s/secrets.yaml" ] && grep -v "base64-encoded" k8s/secrets.yaml &>/dev/null; then
        kubectl apply -f k8s/secrets.yaml
        print_success "Secrets applied"
    else
        print_warning "Secrets not configured. Please update k8s/secrets.yaml"
    fi
    
    # Deploy Kafka infrastructure
    print_status "Deploying Kafka infrastructure..."
    kubectl apply -f k8s/kafka-deployment.yaml
    
    # Wait for Kafka to be ready
    print_status "Waiting for Kafka to be ready..."
    kubectl wait --for=condition=ready pod -l app=kafka -n mlip-system --timeout=300s
    
    # Deploy applications
    print_status "Deploying applications..."
    kubectl apply -f k8s/inference-deployment.yaml
    kubectl apply -f k8s/web-ui-deployment.yaml
    kubectl apply -f k8s/monitoring-deployment.yaml
    kubectl apply -f k8s/training-cronjob.yaml
    
    # Wait for deployments to be ready
    print_status "Waiting for deployments to be ready..."
    kubectl rollout status deployment/inference-deployment -n mlip-system --timeout=300s
    kubectl rollout status deployment/web-ui-deployment -n mlip-system --timeout=300s
    kubectl rollout status deployment/grafana -n mlip-system --timeout=300s
    
    # Apply ingress (if configured)
    if [ -f "k8s/ingress.yaml" ]; then
        kubectl apply -f k8s/ingress.yaml
        print_success "Ingress applied"
    fi
    
    print_success "Kubernetes deployment completed"
    show_kubernetes_status
}

show_kubernetes_status() {
    echo
    echo -e "${BLUE}=== Kubernetes Status ===${NC}"
    echo "Namespace:     mlip-system"
    echo
    echo "Pods:"
    kubectl get pods -n mlip-system
    echo
    echo "Services:"
    kubectl get services -n mlip-system
    echo
    echo "Ingress:"
    kubectl get ingress -n mlip-system 2>/dev/null || echo "No ingress configured"
    echo
    echo -e "${BLUE}=== Access Commands ===${NC}"
    echo "# Port forward services:"
    echo "kubectl port-forward service/web-ui-service 5000:5000 -n mlip-system"
    echo "kubectl port-forward service/inference-service 5001:5001 -n mlip-system"
    echo "kubectl port-forward service/grafana-service 3000:3000 -n mlip-system"
    echo
}

# Deploy to staging environment
deploy_staging() {
    print_status "Deploying to staging environment..."
    
    # Check if we have staging kubeconfig
    if [ ! -f "$KUBE_CONFIG_STAGING" ]; then
        print_error "KUBE_CONFIG_STAGING environment variable not set"
        exit 1
    fi
    
    export KUBECONFIG="$KUBE_CONFIG_STAGING"
    
    # Deploy to staging
    deploy_kubernetes
    
    # Run integration tests
    print_status "Running integration tests on staging..."
    
    # Get service URLs (this would need to be adapted based on your setup)
    local web_ui_url=$(kubectl get service web-ui-service -n mlip-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")
    local inference_url=$(kubectl get service inference-service -n mlip-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")
    
    if [ -f "tests/integration_test.py" ]; then
        python tests/integration_test.py --web-ui-url http://$web_ui_url:5000 --inference-url http://$inference_url:5001
        print_success "Integration tests passed"
    else
        print_warning "Integration tests not found"
    fi
    
    print_success "Staging deployment completed"
}

# Deploy to production environment
deploy_production() {
    print_status "Deploying to production environment..."
    
    # Check if we have production kubeconfig
    if [ ! -f "$KUBE_CONFIG_PRODUCTION" ]; then
        print_error "KUBE_CONFIG_PRODUCTION environment variable not set"
        exit 1
    fi
    
    export KUBECONFIG="$KUBE_CONFIG_PRODUCTION"
    
    # Deploy to production with additional checks
    deploy_kubernetes
    
    # Run smoke tests
    print_status "Running smoke tests on production..."
    
    # Get ingress URL
    local ingress_url=$(kubectl get ingress mlip-ingress -n mlip-system -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "localhost")
    
    if [ -f "tests/smoke_test.py" ]; then
        python tests/smoke_test.py --url https://$ingress_url
        print_success "Smoke tests passed"
    else
        print_warning "Smoke tests not found"
    fi
    
    print_success "Production deployment completed"
}

# Update deployment
update_deployment() {
    local service=${1:-all}
    
    print_status "Updating deployment for: $service"
    
    case $service in
        "inference")
            kubectl rollout restart deployment/inference-deployment -n mlip-system
            kubectl rollout status deployment/inference-deployment -n mlip-system
            ;;
        "web")
            kubectl rollout restart deployment/web-ui-deployment -n mlip-system
            kubectl rollout status deployment/web-ui-deployment -n mlip-system
            ;;
        "training")
            kubectl delete jobs --all -n mlip-system --cascade=false
            kubectl create job manual-training-$(date +%s) --from=cronjob/model-training-cronjob -n mlip-system
            ;;
        "all")
            kubectl rollout restart deployment/inference-deployment -n mlip-system
            kubectl rollout restart deployment/web-ui-deployment -n mlip-system
            kubectl rollout restart deployment/grafana -n mlip-system
            kubectl rollout status deployment/inference-deployment -n mlip-system
            kubectl rollout status deployment/web-ui-deployment -n mlip-system
            kubectl rollout status deployment/grafana -n mlip-system
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available services: inference, web, training, all"
            exit 1
            ;;
    esac
    
    print_success "Deployment updated for $service"
}

# Scale services
scale_service() {
    local service=$1
    local replicas=$2
    
    if [ -z "$service" ] || [ -z "$replicas" ]; then
        print_error "Usage: $0 scale <service> <replicas>"
        echo "Available services: inference, web"
        exit 1
    fi
    
    print_status "Scaling $service to $replicas replicas..."
    
    case $service in
        "inference")
            kubectl scale deployment inference-deployment --replicas=$replicas -n mlip-system
            ;;
        "web")
            kubectl scale deployment web-ui-deployment --replicas=$replicas -n mlip-system
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available services: inference, web"
            exit 1
            ;;
    esac
    
    print_success "Scaled $service to $replicas replicas"
}

# Get deployment status
get_status() {
    local environment=${1:-local}
    
    case $environment in
        "local")
            print_status "Local deployment status:"
            docker-compose -f docker-compose.kafka.yaml ps
            ;;
        "k8s"|"kubernetes")
            print_status "Kubernetes deployment status:"
            kubectl get pods,svc,hpa -n mlip-system
            ;;
        "staging")
            if [ -f "$KUBE_CONFIG_STAGING" ]; then
                export KUBECONFIG="$KUBE_CONFIG_STAGING"
                print_status "Staging deployment status:"
                kubectl get pods,svc,hpa -n mlip-system
            else
                print_error "Staging kubeconfig not found"
            fi
            ;;
        "production")
            if [ -f "$KUBE_CONFIG_PRODUCTION" ]; then
                export KUBECONFIG="$KUBE_CONFIG_PRODUCTION"
                print_status "Production deployment status:"
                kubectl get pods,svc,hpa -n mlip-system
            else
                print_error "Production kubeconfig not found"
            fi
            ;;
        *)
            print_error "Unknown environment: $environment"
            echo "Available environments: local, k8s, staging, production"
            exit 1
            ;;
    esac
}

# Cleanup deployment
cleanup() {
    local environment=${1:-local}
    
    print_warning "This will remove all deployments in $environment environment"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        case $environment in
            "local")
                print_status "Cleaning up local deployment..."
                docker-compose -f docker-compose.kafka.yaml down -v
                docker system prune -f
                ;;
            "k8s"|"kubernetes")
                print_status "Cleaning up Kubernetes deployment..."
                kubectl delete namespace mlip-system --ignore-not-found
                ;;
            *)
                print_error "Unknown environment: $environment"
                exit 1
                ;;
        esac
        print_success "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  ML Engagement Prediction System    ${NC}"
    echo -e "${BLUE}           Deployment Script           ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Load environment variables
    load_env
    
    # Parse command line arguments
    case "${1:-help}" in
        "local")
            deploy_local
            ;;
        "k8s"|"kubernetes")
            deploy_kubernetes
            ;;
        "staging")
            deploy_staging
            ;;
        "production"|"prod")
            deploy_production
            ;;
        "update")
            update_deployment "${2:-all}"
            ;;
        "scale")
            scale_service "$2" "$3"
            ;;
        "status")
            get_status "$2"
            ;;
        "cleanup")
            cleanup "$2"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 <command> [options]"
            echo
            echo "Deployment Commands:"
            echo "  local           - Deploy to local Docker environment"
            echo "  k8s/kubernetes  - Deploy to Kubernetes cluster"
            echo "  staging         - Deploy to staging environment"
            echo "  production/prod - Deploy to production environment"
            echo
            echo "Management Commands:"
            echo "  update [service] - Update deployment (inference, web, training, all)"
            echo "  scale <service> <replicas> - Scale service"
            echo "  status [env]    - Show deployment status"
            echo "  cleanup [env]   - Clean up deployment"
            echo
            echo "Examples:"
            echo "  $0 local                    # Deploy locally"
            echo "  $0 k8s                      # Deploy to Kubernetes"
            echo "  $0 update inference         # Update inference service"
            echo "  $0 scale inference 5         # Scale inference to 5 replicas"
            echo "  $0 status k8s               # Show Kubernetes status"
            echo "  $0 cleanup local            # Clean up local deployment"
            exit 0
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Run '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
