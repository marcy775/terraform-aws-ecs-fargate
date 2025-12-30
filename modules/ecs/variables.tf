variable "name" {
  description = "Name resource"
  type        = string
}

variable "ecr_repository_url" {
  type = string
}

variable "region" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_tg_arn" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "vpc_id" {
  type = string
}