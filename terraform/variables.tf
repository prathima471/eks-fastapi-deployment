# ============================================================================
# VARIABLES.TF — All configurable parameters in one place
# ============================================================================
# Like Ansible vars file — define all variables here,
# set values in dev.tfvars or prod.tfvars per environment.
# ============================================================================

variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging all resources"
  type        = string
  default     = "eks-fastapi"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ── VPC Settings ──
variable "vpc_cidr" {
  description = "CIDR block for the VPC (the IP range of your private network)"
  type        = string
  default     = "10.0.0.0/16"   # 65,536 IPs
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT Gateway go here)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS nodes go here - secure!)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# ── EKS Settings ──
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.micro"   # 2 vCPU, 4GB RAM — good for dev
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size in GB for each worker node"
  type        = number
  default     = 30
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo (e.g. john/eks-fastapi-deployment)"
  type        = string
}
