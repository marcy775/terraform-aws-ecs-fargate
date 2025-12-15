################################
# VPC Module                   #
################################
module "vpc" {
  source = "../../modules/vpc"

  name = var.name
  vpc_cidr = var.vpc_cidr
  azs = var.azs

  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

################################
# ALB Module                   #
################################
module "alb" {
  source = "../../modules/alb"

  name = var.name
  vpc_id = module.vpc.vpc_id.id
  subnet_ids = module.vpc.public_subnet_ids
}