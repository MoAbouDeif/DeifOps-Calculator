module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${terraform.workspace}-${var.cluster_name}"
  kubernetes_version = var.cluster_version

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }

  }

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = local.tags
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "ebs_csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:ebs-csi-controller-sa",
        "kube-system:ebs-csi-node-sa"
      ]
    }
  }

  tags = local.tags
}

resource "aws_eks_addon" "ebs_csi" {
  depends_on               = [module.eks.eks_managed_node_groups]
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_irsa.arn
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "cert_manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "cert_manager:cert_manager",
        "cert_manager:cert_manager-cainjector",
        "cert_manager:cert_manager-webhook",
        "cert_manager:default"
      ]
    }
  }

  tags = local.tags
}

resource "aws_eks_addon" "cert_manager" {
  depends_on               = [module.eks.eks_managed_node_groups]
  cluster_name             = module.eks.cluster_name
  addon_name               = "cert-manager"
  service_account_role_arn = module.cert_manager_irsa.arn
}

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "external_dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "external_dns:external_dns",
        "external_dns:default"
      ]
    }
  }

  tags = local.tags
}

resource "aws_eks_addon" "external_dns" {
  depends_on               = [module.eks.eks_managed_node_groups]
  cluster_name             = module.eks.cluster_name
  addon_name               = "external-dns"
  service_account_role_arn = module.external_dns_irsa.arn
}

module "load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "load_balancer_controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "aws-load-balancer-controller:aws-load-balancer-controller",
        "aws-load-balancer-controller:default"
      ]
    }
  }

  tags = local.tags
}
