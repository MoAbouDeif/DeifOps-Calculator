variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type    = string
  default = "eks-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.33"
}

variable "compute_config" {
  type = object({
    enabled    = bool
    node_pools = list(string)
  })
  default = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24", "10.0.14.0/24", "10.0.15.0/24", "10.0.16.0/24"]
}

variable "tags" {
  type = map(string)
  default = {
    Terraform = "true"
  }
}

variable "eks_managed_node_groups" {
  type = map(object({
    ami_type       = string
    instance_types = list(string)

    min_size     = number
    max_size     = number
    desired_size = number
  }))

  default = {
    "calculator_app" = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 10
      desired_size = 2
    }
  }
}
