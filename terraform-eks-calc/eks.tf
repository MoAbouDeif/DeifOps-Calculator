###############################################################################
# EKS module
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      service_account_role_arn = module.cert_manager_irsa.arn
    }
    aws-ebs-csi-driver = {
      name                     = "aws-ebs-csi-driver"
      service_account_role_arn = module.aws_ebs_csi_driver_irsa.arn
    }
    aws-efs-csi-driver = {
      name                     = "aws-efs-csi-driver"
      service_account_role_arn = module.aws_efs_csi_driver_irsa.arn
    }
    # aws-mountpoint-s3-csi-driver = {
    #   name                     = "aws-mountpoint-s3-csi-driver"
    #   service_account_role_arn = module.aws_mountpoint_s3_csi_driver_irsa.arn
    # }
    external-dns = {
      name                     = "external-dns"
      service_account_role_arn = module.external_dns_irsa.arn
    }
    amazon-cloudwatch-observability = {
      name                     = "amazon-cloudwatch-observability"
      service_account_role_arn = module.cloudwatch_agent_irsa.arn
    }

  }

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets



  eks_managed_node_groups =  {
    "calc_node_group" = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]
      capacity_type  = "SPOT"
      desired_size = 2
      min_size     = 1
      max_size     = 6
    }
  }

  tags = local.tags
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  service_account_ = 

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

###############################################################################
# aws-ebs-csi-driver IRSA
###############################################################################
module "aws_ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "aws-ebs-csi-driver"

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
}

###############################################################################
# aws-efs-csi-driver IRSA
###############################################################################
module "aws_efs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "aws-efs-csi-driver"

  attach_efs_csi_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:efs-csi-controller-sa",
        "kube-system:efs-csi-node-sa"
      ]
    }
  }
}

###############################################################################
# aws-mountpoint-s3-csi-driver IRSA
###############################################################################
# module "aws_mountpoint_s3_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "~> 6.0"
#   name    = "aws-mountpoint-s3-csi-driver"

#   attach_mountpoint_s3_csi_policy = true

#   oidc_providers = {
#     oidc = {
#       provider_arn = module.eks.oidc_provider_arn
#       namespace_service_accounts = [
#         "kube-system:aws-mountpoint-s3-csi-driver-sa"
#       ]
#     }
#   }
# }

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

# resource "helm_release" "aws_load_balancer_controller" {
#   chart = "aws-load-balancer-controller"
#   name  = "aws-load-balancer-controller"

#   lint             = true
#   namespace        = "aws-load-balancer-controller"
#   repository       = "https://aws.github.io/eks-charts"
#   version          = "1.13.4"
#   create_namespace = true
#   depends_on = [
#     module.aws_load_balancer_controller_irsa,
#     module.eks.eks_managed_node_groups,
#     helm_release.cert_manager_controller
#   ]
#   set = [
#     {
#       name  = "serviceAccount.create"
#       value = "true"
#     },
#     {
#       name  = "serviceAccount.name"
#       value = "aws-load-balancer-controller"
#     },
#     {
#       name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#       value = "${module.aws_load_balancer_controller_irsa.arn}"
#     },
#     {
#       name  = "vpcId"
#       value = module.vpc.vpc_id
#     },
#     {
#       name  = "region"
#       value = var.aws_region
#     },
#     {
#       name  = "clusterName"
#       value = module.eks.cluster_name
#     },
#     {
#       name  = "replicaCount"
#       value = "2"
#     },
#     {
#       name  = "enableCertManager"
#       value = true
#     },
#     {
#       name  = "clusterSecretsPermissions.allowAllSecrets"
#       value = true
#     }
#   ]
# }

###############################################################################
# cert-manager and IRSA
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

# resource "helm_release" "cert_manager_controller" {
#   chart = "cert-manager"
#   name  = "cert-manager"

#   namespace        = "cert-manager"
#   create_namespace = true
#   lint             = true
#   repository       = "https://charts.jetstack.io"
#   version          = "1.18.2"
#   depends_on = [
#     module.cert_manager_irsa,
#     module.eks.eks_managed_node_groups
#   ]
#   set = [
#     {
#       name  = "serviceAccount.create"
#       value = "true"
#     },
#     {
#       name  = "cainjector.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#       value = "${module.cert_manager_irsa.arn}"
#     },
#     {
#       name  = "installCRDs"
#       value = "true"
#     },
#   ]
# }

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

###############################################################################
# amazon-cloudwatch-observability IRSA
###############################################################################
module "cloudwatch_agent_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "cloudwatch-agent-irsa"

  attach_cloudwatch_observability_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "amazon-cloudwatch:amazon-cloudwatch-observability-controller-manager",
        "amazon-cloudwatch:cloudwatch-agent",
        "amazon-cloudwatch:neuron-monitor-service-acct",
        "amazon-cloudwatch:dcgm-exporter-service-acct"
      ]
    }
  }

  tags = local.tags
}

###############################################################################
# vpc-cni IRSA
###############################################################################
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "vpc-cni-irsa"

  attach_vpc_cni_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:vpc-cni"
      ]
    }
  }

  tags = local.tags
}
