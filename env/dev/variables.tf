variable "name" {
  description = "Name resource"
  type = string
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type = string
}

variable "azs" {
  description = "Avalilability Zones"
  type = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type = list(string)
}

# IAM

# ECS
variable "region" {
  type = string
}