.PHONY: get-env init plan apply destroy

get-env:
ifndef ENV
	$(eval ENV := $(shell read -p "ENV is not set. Enter the environment name: " input && echo $$input))
endif

all: init plan apply

destroy-all: destroy

## Environment resources
init: get-env
	@echo "==> Initializing Terraform backend and providers..."
	@terraform -chdir=env/$(ENV)/modules init -backend-config=../../../env/$(ENV)/vars/backend.tfvars -reconfigure --upgrade

plan: get-env init
	@echo "==> Generating Terraform execution plan..."
	@terraform -chdir=env/$(ENV)/modules plan -var-file=../../../env/$(ENV)/vars/terraform.tfvars

apply: get-env init
	@echo "==> Applying infrastructure to AWS..."
	@terraform -chdir=env/$(ENV)/modules apply -var-file=../../../env/$(ENV)/vars/terraform.tfvars -auto-approve

destroy: get-env init
	@echo "==> Destroying AWS resources..."
	@terraform -chdir=env/$(ENV)/modules destroy -var-file=../../../env/$(ENV)/vars/terraform.tfvars
