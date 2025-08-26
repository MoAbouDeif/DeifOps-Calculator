###############################################################################
# EKS module (unchanged)
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  depends_on = [ module.vpc ]
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

###############################################################################
# EBS CSI IRSA (unchanged)
###############################################################################
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

###############################################################################
# cert-manager IRSA — FIXED namespace:serviceAccount strings (use hyphens)
###############################################################################
module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "cert_manager"

  # This flag (module option) should attach a policy that allows Route53 changes.
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn

      # *** corrected values: namespace and service account names use hyphen ***
      namespace_service_accounts = [
        "cert-manager:cert-manager",
        "cert-manager:cert-manager-cainjector",
        "cert-manager:cert-manager-webhook",
        "cert-manager:default"
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

resource "kubernetes_manifest" "cert_manager_webhook_ready" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Pod"
    "metadata" = {
      "name"      = "cert-manager-webhook-probe"
      "namespace" = "cert-manager"
    }
    "spec" = {
      "containers" = [
        {
          "name"    = "curl"
          "image"   = "curlimages/curl:8.7.1"
          "command" = ["sh", "-c", "until curl -k https://cert-manager-webhook.cert-manager.svc/healthz; do echo waiting; sleep 5; done; sleep 10"]
        }
      ]
      "restartPolicy" = "Never"
    }
  }

  wait_for = {
    "condition" = [
      {
        type   = "Succeeded"
        status = "True"
      }
    ]
  }

  depends_on = [aws_eks_addon.cert_manager]
}

###############################################################################
# external-dns IRSA — FIXED namespace:serviceAccount strings (use hyphens)
###############################################################################
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "external_dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      # corrected values:
      namespace_service_accounts = [
        "external-dns:external-dns",
        "external-dns:default"
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

###############################################################################
# Load Balancer Controller IRSA — normalize SA mapping
###############################################################################
module "load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name    = "load_balancer_controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    oidc = {
      provider_arn = module.eks.oidc_provider_arn
      # controller uses namespace "aws-load-balancer-controller" and SA "aws-load-balancer-controller"
      namespace_service_accounts = [
        "aws-load-balancer-controller:aws-load-balancer-controller"
      ]
    }
  }

  tags = local.tags
}

###############################################################################
# K8s namespace + SA (Terraform-managed) - keep these if you prefer TF ownership
###############################################################################
resource "kubernetes_namespace" "aws_load_balancer_controller" {
  metadata {
    name = "aws-load-balancer-controller"
  }
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = kubernetes_namespace.aws_load_balancer_controller.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.load_balancer_controller_irsa.arn
    }
  }
}

###############################################################################
# Helm release for aws-load-balancer-controller (serviceAccount.create=false)
###############################################################################
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"

  set = [
    { name = "clusterSecretsPermissions.allowAllSecrets" , value = "true" },
    { name = "enableCertManager", value = "true" },
    { name = "vpcId", value = module.vpc.vpc_id },
    { name = "region", value = var.aws_region },
    { name = "clusterName", value = module.eks.cluster_name },
    { name = "serviceAccount.create", value = "false" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.load_balancer_controller_irsa.arn }
  ]

  depends_on = [
    module.eks,
    module.load_balancer_controller_irsa,
    kubernetes_service_account.aws_load_balancer_controller,
    kubernetes_cluster_role.alb_leases,
    kubernetes_cluster_role_binding.alb_leases_binding,
    kubernetes_manifest.cert_manager_webhook_ready
  ]
}

###############################################################################
# Small ClusterRole + Binding for leases (leader election) — minimal and additive
# (You already added this; keeping it here)
###############################################################################
resource "kubernetes_cluster_role" "alb_leases" {
  metadata { name = "alb-leases" }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "watch", "list", "create", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "alb_leases_binding" {
  metadata { name = "alb-leases-binding" }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.alb_leases.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    namespace = kubernetes_namespace.aws_load_balancer_controller.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.aws_load_balancer_controller,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}
