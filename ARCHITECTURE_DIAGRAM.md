# Diagrama de Arquitectura del Sistema MLOps

## Arquitectura General

```mermaid
graph TB
    subgraph "Data Layer"
        A[User Events] --> B[Apache Kafka]
        B --> C[Feature Store]
        D[Training Data] --> C
    end
    
    subgraph "ML Pipeline"
        C --> E[Training Service]
        E --> F[Weights & Biases]
        F --> G[Model Registry]
        G --> H[Inference Service]
    end
    
    subgraph "Application Layer"
        I[Web UI] --> J[API Gateway]
        K[Mobile App] --> J
        J --> H
        H --> L[Load Balancer]
    end
    
    subgraph "Infrastructure Layer"
        M[Docker Containers] --> N[Kubernetes Cluster]
        N --> O[Auto-scaling]
        P[Helm Charts] --> N
    end
    
    subgraph "Monitoring Layer"
        Q[Prometheus] --> R[Grafana Dashboards]
        F --> S[W&B Dashboards]
        T[Logs] --> U[ELK Stack]
        Q --> T
    end
    
    subgraph "CI/CD Layer"
        V[GitHub Repository] --> W[GitHub Actions]
        W --> X[Testing Pipeline]
        X --> Y[Deployment Pipeline]
        Y --> N
    end
```

## Flujo de Datos Detallado

```mermaid
sequenceDiagram
    participant U as User
    participant G as API Gateway
    participant I as Inference Service
    participant M as Model Registry
    participant W as W&B
    participant P as Prometheus
    participant K as Kafka
    
    U->>G: Prediction Request
    G->>I: Forward Request
    I->>M: Load Model
    I->>I: Make Prediction
    I->>W: Log Prediction
    I->>P: Log Metrics
    I->>G: Return Response
    G->>U: Prediction Result
    
    Note over K: Async Data Stream
    U->>K: User Events
    K->>I: Trigger Batch Processing
    I->>W: Log Batch Results
```

## Componentes del Sistema

### 1. Data Streaming Layer
```mermaid
graph LR
    A[Web App] --> B[Kafka Producer]
    C[Mobile App] --> B
    D[IoT Devices] --> B
    B --> E[Kafka Cluster]
    E --> F[Stream Processing]
    F --> G[Feature Store]
    F --> H[Real-time Dashboard]
```

### 2. ML Training Pipeline
```mermaid
graph TB
    A[Trigger: CronJob] --> B[Data Validation]
    B --> C[Feature Engineering]
    C --> D[Model Training]
    D --> E[Model Evaluation]
    E --> F[W&B Logging]
    F --> G[Model Registry]
    G --> H[Model Promotion]
    H --> I[Kubernetes Deployment]
```

### 3. Inference Architecture
```mermaid
graph TB
    A[Client Request] --> B[API Gateway]
    B --> C[Load Balancer]
    C --> D[Inference Pod 1]
    C --> E[Inference Pod 2]
    C --> F[Inference Pod N]
    D --> G[Model Cache]
    E --> G
    F --> G
    G --> H[Prediction]
    H --> I[W&B Logging]
    H --> J[Response]
```

### 4. Monitoring Stack
```mermaid
graph TB
    A[Application Metrics] --> B[Prometheus]
    C[System Metrics] --> B
    D[Business Metrics] --> B
    B --> E[Grafana]
    B --> F[AlertManager]
    F --> G[Slack/Email]
    H[W&B Metrics] --> I[W&B Dashboard]
    J[Logs] --> K[ELK Stack]
```

## Especificaciones Técnicas

### Kubernetes Cluster
```yaml
# Namespace Configuration
apiVersion: v1
kind: Namespace
metadata:
  name: mlip-system
  labels:
    name: mlip-system

---
# Resource Quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mlip-quota
  namespace: mlip-system
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

### Service Mesh Architecture
```mermaid
graph TB
    A[Ingress Controller] --> B[API Gateway]
    B --> C[Service Mesh: Istio]
    C --> D[Inference Service]
    C --> E[Training Service]
    C --> F[Monitoring Service]
    
    subgraph "Observability"
        G[Jaeger Tracing]
        H[Kiali Dashboard]
        I[Prometheus]
    end
    
    C --> G
    C --> H
    C --> I
```

## Deployment Architecture

### Staging Environment
```mermaid
graph LR
    A[GitHub: main] --> B[CI Pipeline]
    B --> C[Build Images]
    C --> D[Unit Tests]
    D --> E[Integration Tests]
    E --> F[Deploy to Staging]
    F --> G[E2E Tests]
    G --> H[Manual Approval]
```

### Production Environment
```mermaid
graph LR
    A[GitHub: main] --> B[CI Pipeline]
    B --> C[Build Images]
    C --> D[Security Scanning]
    D --> E[Deploy Blue/Green]
    E --> F[Health Checks]
    F --> G[Traffic Switch]
    G --> H[Monitor Rollback]
```

## Data Flow Architecture

### Real-time Processing
```mermaid
graph TB
    A[User Events] --> B[Kafka Topics]
    B --> C[Stream Processor]
    C --> D[Feature Store]
    D --> E[Inference Service]
    E --> F[Prediction Results]
    F --> G[Result Store]
    G --> H[Dashboard]
```

### Batch Processing
```mermaid
graph TB
    A[Scheduled Trigger] --> B[Data Extractor]
    B --> C[Batch Processor]
    C --> D[Model Training]
    D --> E[Model Evaluation]
    E --> F[Model Deployment]
    F --> G[Batch Inference]
    G --> H[Results Storage]
```

## Security Architecture

```mermaid
graph TB
    A[External User] --> B[API Gateway: OAuth]
    B --> C[Service Mesh: mTLS]
    C --> D[Pod Security Policies]
    D --> E[Network Policies]
    E --> F[Secrets Management]
    
    subgraph "Security Components"
        G[Vault]
        H[RBAC]
        I[Pod Security Standards]
    end
    
    F --> G
    F --> H
    F --> I
```

## High Availability Design

```mermaid
graph TB
    subgraph "Multi-AZ Deployment"
        A[Zone A] --> B[Inference Pods]
        C[Zone B] --> D[Inference Pods]
        E[Zone C] --> F[Inference Pods]
    end
    
    subgraph "Load Balancing"
        G[Global Load Balancer]
        H[Regional Load Balancers]
    end
    
    G --> H
    H --> A
    H --> C
    H --> E
    
    subgraph "Data Replication"
        I[Primary Database]
        J[Replica 1]
        K[Replica 2]
    end
    
    I --> J
    I --> K
```

## Performance Optimization

### Caching Strategy
```mermaid
graph LR
    A[Request] --> B[CDN Cache]
    B --> C[API Gateway Cache]
    C --> D[Model Cache]
    D --> E[Feature Cache]
    E --> F[Database Cache]
```

### Auto-scaling Configuration
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: inference-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: inference-service
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Disaster Recovery

```mermaid
graph TB
    A[Primary Cluster] --> B[Data Replication]
    B --> C[Backup Cluster]
    
    D[Health Monitoring] --> E[Failure Detection]
    E --> F[Automatic Failover]
    F --> C
    
    G[Manual Recovery] --> H[Service Restoration]
    H --> A
```

## Integration Points

### External Systems
```mermaid
graph LR
    A[CRM System] --> B[Data Ingestion]
    C[Analytics Platform] --> D[Metrics Export]
    E[Notification Service] --> F[Alert Integration]
    G[Identity Provider] --> H[Authentication]
```

### Internal Services
```mermaid
graph TB
    A[API Gateway] --> B[Inference Service]
    A --> C[Training Service]
    A --> D[Monitoring Service]
    
    B --> E[Model Registry]
    C --> E
    D --> F[Metrics Store]
    
    G[Service Discovery] --> A
    H[Configuration Service] --> A
```
