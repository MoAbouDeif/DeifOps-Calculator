terraform {
  backend "s3" {
    bucket       = "abodaif-terraform-backend"
    key          = "eks-cluster/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
provider "aws" {
  region = var.aws_region
}
