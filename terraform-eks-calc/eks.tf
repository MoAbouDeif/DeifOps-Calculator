###############################################################################
# EKS module
###############################################################################
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
    metrics-server = {}
    aws-ebs-csi-driver = {}
    external-dns = {
      name = "external-dns"
      service_account_role_arn = module.external_dns_irsa.arn
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

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

###############################################################################
# aws-load-balancer-controller with IRSA
###############################################################################
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true
  cert_manager_hosted_zone_arns          = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "aws-load-balancer-controller:aws-load-balancer-controller"
      ]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  chart = "aws-load-balancer-controller"
  name  = "aws-load-balancer-controller"

  lint             = true
  namespace        = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  version          = "1.13.4"
  create_namespace = true
  depends_on       = [
    module.aws_load_balancer_controller_irsa,
    module.eks.eks_managed_node_groups,
    helm_release.cert_manager_controller
    ]
  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${module.aws_load_balancer_controller_irsa.arn}"
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "replicaCount"
      value = "2"
    },
    {
      name = "enableCertManager"
      value = true
    },
    {
      name = "clusterSecretsPermissions.allowAllSecrets"
      value = true
    }
  ]
}

###############################################################################
# cert-manager IRSA
###############################################################################
module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "cert-manager:cert-manager",
        "cert-manager:cert-manager-cainjector",
        "cert-manager:cert-manager-webhook"
      ]
    }
  }

  tags = local.tags
}

resource "helm_release" "cert_manager_controller" {
  chart = "cert-manager"
  name  = "cert-manager"

  namespace = "cert-manager"
  create_namespace = true
  lint             = true
  repository       = "https://charts.jetstack.io"
  version          = "1.18.2"
  depends_on       = [
    module.cert_manager_irsa,
    module.eks.eks_managed_node_groups
    ]
  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "cainjector.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${module.cert_manager_irsa.arn}"
    },
    {
      name = "installCRDs"
      value = "true"
    },
  ]
}

###############################################################################
# external-dns IRSA
###############################################################################
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "external-dns:external-dns"
      ]
    }
  }

  tags = local.tags
}
