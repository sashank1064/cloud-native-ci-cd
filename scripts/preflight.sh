#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

PROJECT_NAME="${PROJECT_NAME:-cloud-native-cicd}"
SERVICE_NAME="${SERVICE_NAME:-user-service}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
CLUSTER_NAME="${CLUSTER_NAME:-cicd-eks-cluster}"
ECR_REPOSITORY="${ECR_REPOSITORY:-${PROJECT_NAME}/${SERVICE_NAME}}"
CHART_PATH="${CHART_PATH:-${ROOT_DIR}/helm/user-service}"
PYTHON_BIN="${PYTHON_BIN:-${ROOT_DIR}/.venv/bin/python}"

if [[ ! -x "${PYTHON_BIN}" ]]; then
  PYTHON_BIN="$(command -v python3 || true)"
fi

check_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    echo "ok: ${command_name}"
  else
    echo "missing: ${command_name}" >&2
    return 1
  fi
}

echo "Checking required local tools"
check_command aws
check_command docker
check_command helm
check_command kubectl
check_command terraform

if [[ -z "${PYTHON_BIN}" ]]; then
  echo "missing: python3" >&2
  exit 1
fi

echo
echo "Checking local app and chart"
"${PYTHON_BIN}" -m pytest "${ROOT_DIR}/microservices/user-service/tests"
helm lint "${CHART_PATH}"
terraform -chdir="${ROOT_DIR}/terraform" fmt -check -recursive

echo
echo "Checking AWS configuration"
if [[ -z "${AWS_ACCOUNT_ID}" ]]; then
  echo "AWS_ACCOUNT_ID is missing. Set it in .env before deploying." >&2
  exit 1
fi

actual_account_id="$(aws sts get-caller-identity --query Account --output text)"
if [[ "${actual_account_id}" != "${AWS_ACCOUNT_ID}" ]]; then
  echo "AWS CLI is authenticated as ${actual_account_id}, but .env expects ${AWS_ACCOUNT_ID}." >&2
  exit 1
fi
echo "ok: AWS account ${actual_account_id}"

if aws eks describe-cluster \
  --name "${CLUSTER_NAME}" \
  --region "${AWS_REGION}" \
  --query "cluster.status" \
  --output text >/tmp/cloud-native-cicd-cluster-status 2>/dev/null; then
  cluster_status="$(< /tmp/cloud-native-cicd-cluster-status)"
  echo "ok: EKS cluster ${CLUSTER_NAME} is ${cluster_status}"
else
  echo "not ready: EKS cluster ${CLUSTER_NAME} does not exist in ${AWS_REGION}" >&2
  echo "Run: terraform -chdir=terraform apply" >&2
  exit 1
fi

if aws ecr describe-repositories \
  --region "${AWS_REGION}" \
  --repository-names "${ECR_REPOSITORY}" >/dev/null 2>&1; then
  echo "ok: ECR repository ${ECR_REPOSITORY}"
else
  echo "not ready: ECR repository ${ECR_REPOSITORY} does not exist in ${AWS_REGION}" >&2
  echo "Run: terraform -chdir=terraform apply" >&2
  exit 1
fi

aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}" >/dev/null
kubectl get nodes

if kubectl get deployment aws-load-balancer-controller -n kube-system >/dev/null 2>&1; then
  echo "ok: AWS Load Balancer Controller is installed"
else
  echo "not ready: AWS Load Balancer Controller is not installed" >&2
  echo "Run: make install-lbc" >&2
  exit 1
fi

echo
echo "Preflight passed. The project is ready for make deploy."
