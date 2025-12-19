variable "name" {
  description = "Name resource"
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "region" {
  type = string
}

variable "execution_role_arn" {
  type = string
}