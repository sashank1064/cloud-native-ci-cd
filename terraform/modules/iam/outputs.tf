output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "aws_load_balancer_controller_policy_arn" {
  value = aws_iam_policy.aws_load_balancer_controller.arn
}
