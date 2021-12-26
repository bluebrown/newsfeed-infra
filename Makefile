include .env

help:
	@echo "Usage: make [command]"
	@echo "Commands:"
	@echo "    help             Shows this help text"
	@echo "    deps             Install dependencies (assumes ubuntu as distro. Must install docker first, i.e. docker desktop)"
	@echo "    apps             Builds the libs and apps in the submodule"
	@echo "    ami              Create a custom machine image containing the java code, using packer and ansible"
	@echo "    images           Build and push container images using docker compose (need to login to your registry first, set registry to use in the .env file)"
	@echo "    classic          Provision the classic infrastructure with terraform"
	@echo "    eks-base         Provision the EKS infrastructure with terraform"
	@echo "    eks-components   Provision the EKS core components with the terraform helm provider"
	@echo "    eks-apps         Deploy the stack with helm in eks with helm"
	@echo "    clean            Clean up all resources"
	@echo ""
	@echo "Note: -auto-approve is used for all terraform commands. Be careful!"
	@echo ""


deps:
	./scripts/deps

apps:
	cd infra-problem && make libs && make

ami: apps
	cd packer && packer init . && packer build -var "newsfeed_token=$(NEWSFEED_SERVICE_TOKEN)" .

classic:
	cd terraform/classic && terraform init && terraform apply \
		-var ami_id="$(shell jq -r '.builds[-1].artifact_id|split(":")[1]' packer/packer-manifest.json)" \
		-auto-approve
	@echo ""
	@echo "Congratulations! The newsfeed app has been sucesfully deployed."
	@echo "Visit the front-end on http://$(shell cd terraform/classic && terraform output -json | jq -r '.frontend_dns.value')"
	@echo ""

images:
	docker-compose build
	docker-compose push

eks-base:
	cd terraform/kubernetes/cluster && terraform init && terraform apply -auto-approve

eks-components:
	cd terraform/kubernetes/components && terraform init && terraform apply -auto-approve

eks-apps:
	./scripts/release
	@echo ""
	@echo "Congratulations! The newsfeed app has been sucesfully deloyed."
	@echo "Visit the front-end on http://$(shell cd terraform/kubernetes/components && terraform output -json | jq -r '.load_balancer_dns.value')"
	@echo ""

clean:
	./scripts/cleanup

.PHONY: help deps apps classic eks-base eks-components eks-apps clean
