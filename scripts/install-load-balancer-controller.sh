#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-cicd-eks-cluster}"

vpc_id="$(terraform -chdir="${ROOT_DIR}/terraform" output -raw vpc_id)"
role_arn="$(terraform -chdir="${ROOT_DIR}/terraform" output -raw aws_load_balancer_controller_role_arn)"

aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set "clusterName=${CLUSTER_NAME}" \
  --set "region=${AWS_REGION}" \
  --set "vpcId=${vpc_id}" \
  --set-string "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${role_arn}" \
  --wait \
  --timeout 5m

kubectl rollout status deployment/aws-load-balancer-controller \
  -n kube-system \
  --timeout=120s
