.PHONY: get-env init plan apply destroy

AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text)
IMAGE_NAME ?= dagster-dummy-pipeline-lab
IMAGE_TAG ?= latest
ECR_REGISTRY = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
FULL_IMAGE_URI = $(ECR_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

get-env:
ifndef ENV
	$(eval ENV := $(shell read -p "ENV is not set. Enter the environment name: " input && echo $$input))
endif

all: init plan apply docker commit

destroy-all: destroy

## Environment resources
init: get-env
	@echo "==> Initializing Terraform backend and providers..."
	@terraform -chdir=env/$(ENV)/modules init -backend-config=../../../env/$(ENV)/vars/backend.tfvars -reconfigure

plan: get-env init
	@echo "==> Generating Terraform execution plan..."
	@terraform -chdir=env/$(ENV)/modules plan -var-file=../../../env/$(ENV)/vars/terraform.tfvars

apply: get-env init
	@echo "==> Applying infrastructure to AWS..."
	@terraform -chdir=env/$(ENV)/modules apply -var-file=../../../env/$(ENV)/vars/terraform.tfvars -auto-approve

docker:
	@echo "==> Docker Build and Push to $(FULL_IMAGE_URI)..."
	@cd ../pipeline && \
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY) && \
	docker build --platform linux/amd64 -t $(IMAGE_NAME):$(IMAGE_TAG) . && \
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(FULL_IMAGE_URI) && \
	docker push $(FULL_IMAGE_URI)

commit:
	@echo "==> Syncing rendered Kubernetes manifests and values to Git..."
	@git add ../kubernetes/values/*.yaml ../kubernetes/manifests/**/*.yaml ../kubernetes/apps/*.yaml env/$(ENV)/modules/argocd/argocd-values.yaml || true
	@git commit -m "chore(k8s): auto-update dynamic values and manifests from terraform apply" || echo "No changes to commit"
	@git push || echo "Git push skipped or failed"

destroy: get-env init
	@echo "==> Destroying AWS resources..."
	@terraform -chdir=env/$(ENV)/modules destroy -var-file=../../../env/$(ENV)/vars/terraform.tfvars
