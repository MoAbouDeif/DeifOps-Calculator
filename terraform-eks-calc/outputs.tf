output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "node_group_id" {
  value = [for ng in values(module.eks.eks_managed_node_groups) : ng.node_group_id]
}

output "kubeconfig_apply" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region} --alias ${terraform.workspace}-${var.cluster_name}"
}

output "hosted_zone_arn" {
  value = data.aws_route53_zone.selected.arn
}

data "aws_eks_cluster_auth" "token" {
  name = module.eks.cluster_name
}
