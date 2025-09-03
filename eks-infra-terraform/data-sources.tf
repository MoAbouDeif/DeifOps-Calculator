data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "selected" {
  name         = "deifops.click"
  private_zone = false
}

data "aws_eks_cluster_auth" "token" {
  depends_on = [module.eks.eks_managed_node_groups]
  name       = module.eks.cluster_name
}

# data "aws_ecrpublic_authorization_token" "token" {}