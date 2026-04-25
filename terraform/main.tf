data "aws_caller_identity" "current" {}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  environment  = var.environment
}

module "ecr" {
  source               = "./modules/ecr"
  project_name         = var.project_name
  environment          = var.environment
  ecr_repositories     = var.ecr_repositories
  image_tag_mutability = var.ecr_image_tag_mutability
}

module "eks" {
  source                                  = "./modules/eks"
  project_name                            = var.project_name
  environment                             = var.environment
  cluster_name                            = var.cluster_name
  subnet_ids                              = module.vpc.private_subnet_ids
  desired_size                            = var.desired_size
  max_size                                = var.max_size
  min_size                                = var.min_size
  instance_types                          = var.instance_types
  cluster_role_arn                        = module.iam.eks_cluster_role_arn
  admin_principal_arn                     = data.aws_caller_identity.current.arn
  aws_load_balancer_controller_policy_arn = module.iam.aws_load_balancer_controller_policy_arn
  node_role_arn                           = module.iam.eks_node_role_arn
  depends_on                              = [module.iam]
}

module "alb_monitoring" {
  source                       = "./modules/alb"
  project_name                 = var.project_name
  environment                  = var.environment
  alert_email                  = var.alert_email
  alb_load_balancer_arn_suffix = var.alb_load_balancer_arn_suffix
}
