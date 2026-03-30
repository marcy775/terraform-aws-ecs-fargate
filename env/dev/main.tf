# backend.tf
terraform {
  backend "s3" {
    bucket = "kirigeso-bucket"
    key = "terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "kirigeso-dynamodb-table"
  }
}

################################
# VPC Module                   #
################################
module "vpc" {
  source = "../../modules/vpc"

  name = var.name
  vpc_cidr = var.vpc_cidr
  azs = var.azs
  region = var.region

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
  region = var.region
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
  vpc_id = module.vpc.vpc_id.id
  ecr_repository_url = module.ecr.ecr_repository_url
  role_arn = module.iam.tf_ecs_role.arn
  alb_tg_arn = module.alb.tf_alb_tg.arn
  alb_sg_id = module.alb.alb_sg.id
  private_subnet_ids = module.vpc.private_subnet_ids
}
################################
# SNS Module                   #
################################
module "sns" {
  source = "../../modules/sns"

  name = var.name
  email = var.email
}


################################
# CloudWatch Module            #
################################
module "cloudwatch" {
  source = "../../modules/cloudwach"

  name = var.name
  sns_topic_arn = module.sns.sns_topic_arn
  alb_arn_suffix = module.alb.alb_arn_suffix
}

################################
# S3 Module                    #
################################
module "s3" {
  source = "../../modules/s3"

  name = var.name
}

################################
# Dynamo DB Module             #
################################
module "dynamodb" {
  source = "../../modules/dynamodb"
  name = var.name
}
