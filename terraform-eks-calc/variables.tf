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

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "subnets_prefix" {
  type    = number
  default = 24
  validation {
    condition     = var.subnets_prefix > tonumber(split("/", var.vpc_cidr)[1])
    error_message = "subnets_prefix must be greater than the VPC CIDR prefix."
  }
}

variable "public_subnets_count" {
  type    = number
  default = 3
  validation {
    condition     = var.public_subnets_count <= (pow(2, (32 - (tonumber(split("/", var.vpc_cidr)[1])) - (32 - var.subnets_prefix))))
    error_message = "too many public subnets for the given VPC CIDR and subnet prefix."
  }
}

variable "private_subnets_count" {
  type    = number
  default = 6
  validation {
    condition     = var.private_subnets_count <= ((pow(2, (32 - (tonumber(split("/", var.vpc_cidr)[1])) - (32 - var.subnets_prefix)))) - var.public_subnets_count)
    error_message = "too many private subnets for the given VPC CIDR and subnet prefix."
  }
}

variable "tags" {
  type = map(string)
  default = {
    Terraform = "true"
    Project   = "EKS Cluster"
    Owner     = "Mohamed Abou Deif"
    Contact   = "Mohamed.AbouDeif@outlook.com"
    CostCenter = "12345"
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
    "calc_node_group" = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 2
      max_size     = 3
      desired_size = 3
    }
  }
}
