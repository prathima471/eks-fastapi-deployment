# 🚀 Production-Grade EKS Deployment with FastAPI

A cloud-native FastAPI microservice deployed on AWS EKS using Terraform for infrastructure, Helm for Kubernetes deployments, and GitHub Actions for CI/CD.

## Architecture

```
GitHub Actions (OIDC Auth)
    │
    ├── Test & Lint
    ├── Build Docker Image
    ├── Trivy Security Scan
    ├── Push to ECR
    └── Deploy via Helm
            │
            ▼
    AWS VPC (10.0.0.0/16)
    ├── Public Subnets (3 AZs)
    │   ├── Application Load Balancer
    │   └── NAT Gateway
    └── Private Subnets (3 AZs)
        └── EKS Cluster
            ├── Managed Node Group (t3.medium × 2)
            └── FastAPI Pods (auto-scaled via HPA)
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Application | FastAPI (Python 3.12) |
| Container | Docker (multi-stage build) |
| Orchestration | Kubernetes (EKS 1.29) |
| Infrastructure | Terraform |
| CI/CD | GitHub Actions (OIDC auth) |
| Package Manager | Helm |
| Image Registry | Amazon ECR |
| Security | Trivy scanning, IRSA, private subnets |
| Auto-scaling | HPA (CPU/Memory based) |

## Project Structure

```
├── app/                          # FastAPI application
│   ├── main.py                   # REST API with health endpoints
│   ├── Dockerfile                # Multi-stage, non-root build
│   └── requirements.txt
├── terraform/                    # Infrastructure as Code
│   ├── providers.tf              # AWS provider config
│   ├── variables.tf              # All configurable parameters
│   ├── vpc.tf                    # VPC, subnets, NAT, route tables
│   ├── iam.tf                    # IAM roles, OIDC provider
│   ├── eks.tf                    # EKS cluster, node group, ECR
│   ├── outputs.tf                # Cluster info, ECR URL
│   └── dev.tfvars                # Dev environment values
├── fastapi-chart/                # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml               # Configurable deployment values
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── hpa.yaml
├── k8s-manifests/                # Raw K8s manifests (for kubectl)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml
└── .github/workflows/
    └── deploy.yaml               # CI/CD pipeline
```

## Quick Start

### Local (Minikube — Free)
```bash
minikube start --driver=docker --memory=4096 --cpus=2
eval $(minikube docker-env)
cd app && docker build -t fastapi-app:v1.0.0 .
cd ../fastapi-chart && helm install fastapi-app .
kubectl port-forward svc/fastapi-app-fastapi-chart 8080:80
# Visit: http://localhost:8080/docs
```

### AWS EKS
```bash
cd terraform
terraform init
terraform apply -var-file="dev.tfvars"
aws eks update-kubeconfig --region us-east-1 --name eks-fastapi-dev
helm install fastapi-app ./fastapi-chart \
  --set image.repository=<ECR_URL> \
  --set image.pullPolicy=Always
```

## Cost Estimate (10 hours)
| Resource | Cost |
|----------|------|
| EKS Control Plane | $1.00 |
| EC2 (2× t3.medium) | $0.83 |
| NAT Gateway | $0.45 |
| Other (EBS, EIP) | $0.22 |
| **Total** | **~$2.50** |

## Security Features
- Private subnets for worker nodes (no direct internet exposure)
- OIDC authentication (no stored AWS credentials)
- Non-root container user
- Trivy vulnerability scanning in CI/CD
- ECR image scanning on push
- IRSA for pod-level IAM roles
