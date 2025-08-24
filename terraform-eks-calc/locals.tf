locals {
  tags = merge(
    var.tags,
    {
      Env = terraform.workspace
    }
  )
}