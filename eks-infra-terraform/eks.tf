
###############################################################################
# EKS module
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
      before_compute = true
    }
    # metrics-server = {
    #   most_recent = true
    #   }
    kube-proxy     = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.aws_ebs_csi_driver_irsa.arn
    }
    aws-efs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.aws_efs_csi_driver_irsa.arn
    }
    # external-dns = {
    #   most_recent = true
    #   service_account_role_arn = module.external_dns_irsa.arn
    # }
    amazon-cloudwatch-observability = {
      most_recent = true
      service_account_role_arn = module.cloudwatch_agent_irsa.arn
    }

  }



  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  include_oidc_root_ca_thumbprint          = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    "calc_node_group" = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 2
      min_size       = 1
      max_size       = 6
    }
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

resource "helm_release" "external_dns" {
  chart = "external-dns"
  name  = "external-dns"

  lint       = true
  repository = "https://kubernetes-sigs.github.io/external-dns"
  version    = "1.18.0"

  namespace        = "external-dns"
  create_namespace = true
  wait             = true

  depends_on = [
    module.eks.eks_managed_node_groups
  ]

  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name = "serviceAccount.name"
      value = "external-dns"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${module.external_dns_irsa.arn}"
    }
  ]
}

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

resource "helm_release" "cert_manager_controller" {
  chart = "cert-manager"
  name  = "cert-manager"

  lint       = true
  repository = "https://charts.jetstack.io"
  version    = "1.18.2"

  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  depends_on = [
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
      name  = "installCRDs"
      value = "true"
    },
  ]
}

###############################################################################
# aws-load-balancer-controller with IRSA
###############################################################################

module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

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

  repository = "https://aws.github.io/eks-charts"
  version    = "1.13.4"
  lint       = true

  create_namespace = true
  namespace        = "aws-load-balancer-controller"
  wait             = true

  depends_on = [
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
      name  = "enableCertManager"
      value = true
    },
    {
      name  = "clusterSecretsPermissions.allowAllSecrets"
      value = true
    }
  ]
}

###############################################################################
# cluster autoscaler 
###############################################################################

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:cluster-autoscaler"
      ]
    }
  }

  tags = local.tags

}
resource "helm_release" "autoscaler" {
  chart = "cluster-autoscaler"
  name  = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  version    = "9.50.1"
  lint       = true

  create_namespace = true
  namespace        = "kube-system"
  wait             = true

  depends_on = [
    module.eks.eks_managed_node_groups,
    module.eks.addons,
    module.cluster_autoscaler_irsa
  ]
  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${module.cluster_autoscaler_irsa.arn}"
    },
    {
      name  = "extraArgs.balance-similar-node-groups"
      value = "true"
    },
  ]
}

###############################################################################
# cluster autoscaler 
###############################################################################

resource "helm_release" "metrics_server" {
  chart = "metrics-server"
  name  = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  version    = "3.13.0"
  lint       = true

  create_namespace = true
  namespace        = "metric-server"
  wait             = true

  depends_on = [
    module.eks.eks_managed_node_groups,
  ]

  set = [
    {
      name = "serviceAccount.create"
      value = true
    },
    {
      name = "rbac.create"
      value = true
    },
    # {
    #   name = "args"
    #   value = ""
    # }
  ]
}