output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "region" { value = var.region }
output "cluster_name" { value = var.cluster_name }
output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnets" { value = module.vpc.private_subnets }
output "eks_cluster_endpoint" { value = module.eks.cluster_endpoint }
output "eks_oidc_provider_arn" { value = module.eks.oidc_provider_arn }
output "gha_role_arn" {
  value = aws_iam_role.gha_ecr.arn
}