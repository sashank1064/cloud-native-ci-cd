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
IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}"
HELM_RELEASE="${HELM_RELEASE:-user-service}"
HELM_NAMESPACE="${HELM_NAMESPACE:-default}"
CHART_PATH="${CHART_PATH:-${ROOT_DIR}/helm/user-service}"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-${ROOT_DIR}/microservices/user-service}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
INGRESS_HOST="${INGRESS_HOST:-}"

if [[ -z "${AWS_ACCOUNT_ID}" ]]; then
  echo "AWS_ACCOUNT_ID is required. Set it in .env or export it before running deploy." >&2
  exit 1
fi

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_REPOSITORY="${ECR_REGISTRY}/${ECR_REPOSITORY}"
IMAGE_URI="${IMAGE_REPOSITORY}:${IMAGE_TAG}"

echo "Building ${IMAGE_URI}"
docker build -t "${IMAGE_URI}" "${DOCKER_CONTEXT}"

echo "Logging in to ECR ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "Pushing ${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "Updating kubeconfig for ${CLUSTER_NAME}"
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

helm_args=(
  upgrade --install "${HELM_RELEASE}" "${CHART_PATH}"
  --namespace "${HELM_NAMESPACE}"
  --create-namespace
  --set "image.repository=${IMAGE_REPOSITORY}"
  --set "image.tag=${IMAGE_TAG}"
  --set "env.ENVIRONMENT=${ENVIRONMENT}"
  --set "env.VERSION=${IMAGE_TAG}"
  --atomic
  --wait
  --timeout 10m
)

if [[ -n "${INGRESS_HOST}" ]]; then
  helm_args+=(--set "ingress.hosts[0].host=${INGRESS_HOST}")
fi

echo "Deploying ${HELM_RELEASE} to namespace ${HELM_NAMESPACE}"
helm "${helm_args[@]}"

echo "Deployed ${IMAGE_URI}"
