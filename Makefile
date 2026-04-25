PROJECT_NAME ?= cloud-native-cicd
SERVICE_NAME ?= user-service
AWS_REGION ?= us-east-1
CLUSTER_NAME ?= cicd-eks-cluster
ECR_REPOSITORY ?= $(PROJECT_NAME)/$(SERVICE_NAME)
IMAGE_TAG ?= latest
HELM_RELEASE ?= user-service
HELM_NAMESPACE ?= default
DOCKER_CONTEXT ?= microservices/user-service
CHART_PATH ?= helm/user-service
DOCKER_PLATFORM ?= linux/amd64

ifneq (,$(wildcard .env))
include .env
export
endif

ECR_REGISTRY := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_REPOSITORY := $(ECR_REGISTRY)/$(ECR_REPOSITORY)
IMAGE_URI := $(IMAGE_REPOSITORY):$(IMAGE_TAG)

.PHONY: build push deploy install-lbc preflight status url require-aws-account

require-aws-account:
	@test -n "$(AWS_ACCOUNT_ID)" || (echo "AWS_ACCOUNT_ID is required. Set it in .env or export it first." >&2; exit 1)

build: require-aws-account
	docker build --platform $(DOCKER_PLATFORM) -t $(IMAGE_URI) $(DOCKER_CONTEXT)

push: require-aws-account
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)
	docker push $(IMAGE_URI)

deploy:
	./scripts/deploy.sh

install-lbc:
	./scripts/install-load-balancer-controller.sh

preflight:
	./scripts/preflight.sh

status:
	kubectl get pods,svc,ingress -n $(HELM_NAMESPACE)

url:
	kubectl get ingress $(HELM_RELEASE)-$(SERVICE_NAME) -n $(HELM_NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
