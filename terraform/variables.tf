variable "project_name" {
  type    = string
  default = "cloud-native-cicd"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "cluster_name" {
  type    = string
  default = "cicd-eks-cluster"
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 3
}

variable "min_size" {
  type    = number
  default = 1
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "ecr_repositories" {
  type    = list(string)
  default = ["user-service"]
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "Use MUTABLE for the local latest tag workflow."
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "alert_email" {
  type        = string
  description = "Optional email address for ALB alarm notifications."
  default     = ""
}

variable "alb_load_balancer_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for the 5xx alarm. Leave empty on the first apply."
  default     = ""
}
