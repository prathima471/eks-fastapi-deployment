# ============================================================================
# EKS.TF — The Kubernetes Cluster + Container Registry
# ============================================================================
# Creates:
#   1. EKS Cluster (the Kubernetes control plane — AWS manages this)
#   2. Managed Node Group (EC2 worker nodes — your pods run here)
#   3. ECR Repository (stores your Docker images — like DockerHub but private)
# ============================================================================

# ── EKS Cluster ──
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    # Cluster API in private subnets for security
    subnet_ids = concat(
      aws_subnet.private[*].id,
      aws_subnet.public[*].id
    )
    endpoint_private_access = true    # Nodes can reach API server privately
    endpoint_public_access  = true    # You can run kubectl from your laptop
  }

  # Enable logging for debugging
  enabled_cluster_log_types = ["api", "authenticator", "controllerManager"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name        = local.cluster_name
    Environment = var.environment
  }
}

# ── Managed Node Group (Worker Nodes) ──
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id    # Nodes in PRIVATE subnets!

  instance_types = [var.node_instance_type]
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1    # During updates, only 1 node down at a time
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]

  tags = {
    Name        = "${local.cluster_name}-node"
    Environment = var.environment
  }
}

# ── ECR Repository (Your Private Docker Image Registry) ──
resource "aws_ecr_repository" "fastapi_app" {
  name                 = "${local.cluster_name}/fastapi-app"
  image_tag_mutability = "MUTABLE"     # Can overwrite tags (like :latest)
  force_delete         = true          # Allow terraform destroy to delete

  image_scanning_configuration {
    scan_on_push = true    # Scan for vulnerabilities when image is pushed
  }

  tags = {
    Name        = "${local.cluster_name}-fastapi-app"
    Environment = var.environment
  }
}

# ── ECR Lifecycle Policy (auto-cleanup old images) ──
resource "aws_ecr_lifecycle_policy" "fastapi_app" {
  repository = aws_ecr_repository.fastapi_app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
