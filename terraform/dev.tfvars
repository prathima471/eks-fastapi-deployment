# ============================================================================
# DEV.TFVARS — Values for the DEV environment
# ============================================================================
# Usage: terraform apply -var-file="dev.tfvars"
#
# For production, create prod.tfvars with bigger instances, more nodes, etc.
# ============================================================================

aws_region         = "us-east-1"
project_name       = "eks-fastapi"
environment        = "dev"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# EKS
cluster_version    = "1.29"
node_instance_type = "t3.micro"    # $0.0416/hr — good for dev
node_desired_size  = 2               # Start with 2 nodes
node_min_size      = 1
node_max_size      = 3
node_disk_size     = 30              # 30 GB per node
