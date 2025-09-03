output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_apply" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "hosted_zone_arn" {
  value = data.aws_route53_zone.selected.arn
}

output "region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "aws_load_balancer_controller_irsa_arn" {
  value = module.aws_load_balancer_controller_irsa.arn
}
