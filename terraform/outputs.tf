# ============================================================================
# OUTPUTS.TF — What Terraform tells you after deployment
# ============================================================================
# Like the summary at the end of an Ansible playbook run.
# These values are used in the next steps (kubectl, docker push, etc.)
# ============================================================================

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "configure_kubectl" {
  description = "Run this command to connect kubectl to your cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL (use this in docker push)"
  value       = aws_ecr_repository.fastapi_app.repository_url
}

output "ecr_login_command" {
  description = "Run this to login to ECR before docker push"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.fastapi_app.repository_url}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA setup)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN secret in your GitHub repository settings"
  value       = aws_iam_role.github_actions.arn
}
