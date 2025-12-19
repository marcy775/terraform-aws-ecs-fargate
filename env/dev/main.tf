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

################################
# IAM Module                   #
################################
module "iam" {
  source = "../../modules/iam"
  name = var.name
  policy_arn = var.policy_arn
}

################################
# ECR Module                   #
################################
module "ecr" {
  source = "../../modules/ecr"

  name = var.name
}

################################
# ECS Module                   #
################################
module "ecs" {
  source = "../../modules/ecs"

  name = var.name
  region = var.region  
  ecr_repository_url = module.ecr.ecr_repository_url
  tf_ecs_role_arn = module.iam.tf_ecs_role.arn
}