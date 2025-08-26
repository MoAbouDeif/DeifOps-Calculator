data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "selected" {
  name         = "deifops.click"
  private_zone = false
}


data "aws_eks_cluster_auth" "token" {
 name = module.eks.cluster_name 
  region = var.aws_region
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  region = var.aws_region
}