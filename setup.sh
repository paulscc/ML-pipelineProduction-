#!/bin/bash

# ML Engagement Prediction System - Setup Script
# This script sets up the complete MLOps system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3.9+ first."
        exit 1
    fi
    
    # Check kubectl (optional for local development)
    if command -v kubectl &> /dev/null; then
        print_success "kubectl found"
    else
        print_warning "kubectl not found. Kubernetes deployment will not be available."
    fi
    
    print_success "All prerequisites checked!"
}

# Setup environment variables
setup_environment() {
    print_status "Setting up environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
            print_warning "Please edit .env file with your credentials before continuing."
        else
            # Create basic .env file
            cat > .env << EOF
# W&B Configuration
WANDB_API_KEY=your_wandb_api_key_here
WANDB_PROJECT=mlip-engagement-prediction

# Docker Configuration
DOCKER_REGISTRY=your-docker-username
DOCKER_TAG=latest

# Service URLs
WEB_UI_URL=http://localhost:5000
INFERENCE_SERVICE_URL=http://localhost:5001

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Monitoring
PROMETHEUS_URL=http://localhost:9090
GRAFANA_URL=http://localhost:3000

# Kubernetes
NAMESPACE=mlip-system
EOF
            print_success "Created basic .env file"
            print_warning "Please update WANDB_API_KEY and other credentials in .env file."
        fi
    else
        print_success ".env file already exists"
    fi
    
    # Source environment variables
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_success "Environment variables loaded"
    fi
}

# Install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Check if we're in the right directory
    if [ ! -f "requirements.txt" ]; then
        cd mlip-kubernetes-lab
    fi
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_success "Created virtual environment"
    fi
    
    # Activate virtual environment and install dependencies
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Install additional dependencies for the system
    pip install confluent-kafka prometheus-client flask-cors
    
    print_success "Python dependencies installed"
}

# Build Docker images
build_docker_images() {
    print_status "Building Docker images..."
    
    # Navigate to the correct directory
    if [ ! -f "Dockerfile.trainer.enhanced" ]; then
        cd mlip-kubernetes-lab
    fi
    
    # Build all images
    docker build -f Dockerfile.trainer.enhanced -t mlip/trainer:latest .
    docker build -f Dockerfile.backend.enhanced -t mlip/inference:latest .
    docker build -f Dockerfile.web -t mlip/web-ui:latest .
    docker build -f Dockerfile.kafka -t mlip/kafka-processor:latest .
    
    print_success "Docker images built successfully"
}

# Setup W&B
setup_wandb() {
    print_status "Setting up Weights & Biases..."
    
    # Check if W&B is installed
    if ! python -c "import wandb" 2>/dev/null; then
        pip install wandb
    fi
    
    # Login to W&B if API key is provided
    if [ ! -z "$WANDB_API_KEY" ] && [ "$WANDB_API_KEY" != "your_wandb_api_key_here" ]; then
        wandb login "$WANDB_API_KEY"
        print_success "Logged in to Weights & Biases"
    else
        print_warning "WANDB_API_KEY not set. Please set it in .env file and run: wandb login"
    fi
}

# Start local development environment
start_local_dev() {
    print_status "Starting local development environment..."
    
    # Navigate to the correct directory
    if [ ! -f "docker-compose.kafka.yaml" ]; then
        cd mlip-kubernetes-lab
    fi
    
    # Start Kafka stack
    docker-compose -f docker-compose.kafka.yaml up -d
    
    print_success "Local development environment started"
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    if curl -f http://localhost:5000/health &>/dev/null; then
        print_success "Web UI is healthy"
    else
        print_warning "Web UI not yet ready, please wait a moment longer"
    fi
    
    if curl -f http://localhost:5001/health &>/dev/null; then
        print_success "Inference service is healthy"
    else
        print_warning "Inference service not yet ready, please wait a moment longer"
    fi
}

# Run initial tests
run_tests() {
    print_status "Running initial tests..."
    
    # Navigate to the correct directory
    if [ ! -f "tests/integration_test.py" ]; then
        cd mlip-kubernetes-lab
    fi
    
    # Run unit tests
    if [ -d "tests/unit" ]; then
        python -m pytest tests/unit/ -v
        print_success "Unit tests passed"
    fi
    
    # Run integration tests (only if services are running)
    if curl -f http://localhost:5000/health &>/dev/null && curl -f http://localhost:5001/health &>/dev/null; then
        python tests/integration_test.py --web-ui-url http://localhost:5000 --inference-url http://localhost:5001
        print_success "Integration tests passed"
    else
        print_warning "Services not ready, skipping integration tests"
    fi
}

# Setup Kubernetes (optional)
setup_kubernetes() {
    if command -v kubectl &> /dev/null; then
        print_status "Setting up Kubernetes..."
        
        # Create namespace
        kubectl apply -f k8s/namespace.yaml
        
        # Apply configurations
        kubectl apply -f k8s/configmap.yaml
        
        # Create secrets (user needs to update this)
        if [ ! -f "k8s/secrets.yaml" ]; then
            print_warning "Please update k8s/secrets.yaml with your actual secrets"
        fi
        
        print_success "Kubernetes setup completed"
        print_status "You can now deploy with: kubectl apply -f k8s/"
    else
        print_warning "kubectl not found, skipping Kubernetes setup"
    fi
}

# Display next steps
show_next_steps() {
    print_success "Setup completed successfully!"
    echo
    echo -e "${BLUE}=== Next Steps ===${NC}"
    echo
    echo "1. Update your credentials in .env file:"
    echo "   - WANDB_API_KEY"
    echo "   - DOCKER_REGISTRY"
    echo
    echo "2. Access the services:"
    echo "   - Web UI: http://localhost:5000"
    echo "   - Inference API: http://localhost:5001"
    echo "   - Grafana: http://localhost:3000 (admin/admin)"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - Kafka UI: http://localhost:8080"
    echo
    echo "3. Test the system:"
    echo "   curl -X POST http://localhost:5001/predict \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"user_id\": \"test\", \"avg_session_duration\": 25.5, \"visits_per_week\": 8, \"response_rate\": 75.0, \"feature_usage_depth\": 6}'"
    echo
    echo "4. For Kubernetes deployment:"
    echo "   kubectl apply -f k8s/"
    echo "   kubectl get pods -n mlip-system"
    echo
    echo "5. View documentation:"
    echo "   - cat DEPLOYMENT_GUIDE.md"
    echo "   - cat MLIP_SYSTEM_README.md"
    echo
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  ML Engagement Prediction System    ${NC}"
    echo -e "${BLUE}           Setup Script               ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Parse command line arguments
    case "${1:-all}" in
        "prereqs")
            check_prerequisites
            ;;
        "env")
            setup_environment
            ;;
        "deps")
            install_dependencies
            ;;
        "build")
            build_docker_images
            ;;
        "wandb")
            setup_wandb
            ;;
        "start")
            start_local_dev
            ;;
        "test")
            run_tests
            ;;
        "k8s")
            setup_kubernetes
            ;;
        "all")
            check_prerequisites
            setup_environment
            install_dependencies
            build_docker_images
            setup_wandb
            start_local_dev
            run_tests
            setup_kubernetes
            show_next_steps
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  all      - Run complete setup (default)"
            echo "  prereqs  - Check prerequisites only"
            echo "  env      - Setup environment variables"
            echo "  deps     - Install Python dependencies"
            echo "  build    - Build Docker images"
            echo "  wandb    - Setup Weights & Biases"
            echo "  start    - Start local development environment"
            echo "  test     - Run tests"
            echo "  k8s      - Setup Kubernetes"
            echo "  help     - Show this help message"
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
