locals {
  tags = merge(
    var.tags,
    {
      Env = terraform.workspace
    }
  )
}

locals {
  cluster_name    = "${var.cluster_name}-${terraform.workspace}"
  node_group_name = "${local.cluster_name}-node-group"
  vpc_name        = "${local.cluster_name}-vpc"
}

locals {
  # Define subnet sizes
  subnet_prefix = var.subnets_prefix
  public_subnet_cidrs = [
    for i in range(var.public_subnets_count) :
    cidrsubnet(
      var.vpc_cidr,
      local.subnet_prefix - tonumber(split("/", var.vpc_cidr)[1]),
      i
    )
  ]
  private_subnet_cidrs = [
    for i in range(var.private_subnets_count) :
    cidrsubnet(
      var.vpc_cidr,
      local.subnet_prefix - tonumber(split("/", var.vpc_cidr)[1]),
      i + var.public_subnets_count
    )
  ]
}