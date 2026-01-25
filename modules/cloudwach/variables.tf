variable "name" {
  description = "Name resource"
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "alb_arn_suffix" {
  type        = string
}