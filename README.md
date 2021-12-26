# Infrastructure

This repo contains code to provision infrastructure and build container images as well as machine images. These components can be used in different ways to deploy the *newsfeed* stack. The aim is to provide some freedom of choice and flexibility. After the development team has settled on a workflow, the repository could be trimmed down for brevity.

Note that the newsfeed repo (infra-problem), is a  git submodule of this repo. So make sure you clone the repo recursively and to update the submodule if needed.

```bash
git clone --recursive git@github.com:bluebrown/newsfeed-infra.git
cd newsfeed-infra
```

Before working with this repo, you should export the following variables. The region assumed for all deployments is *eu-central-1*.

```bash
export AWS_ACCESS_KEY_ID="<aws-key-id>"
export AWS_SECRET_ACCESS_KEY="aws-secret-key"
```

## Makefile

I would usually recommend to cd into the respective terraform directory and use terraform directly. Also, I would normally control the helm releases from a pipeline. The commands in the makefile exist only to provide the reviewer of this repo a quick way to test the functionalities.

```console
Usage: make [command]
Commands:
    help             Shows this help text
    deps             Install dependencies (assumes ubuntu as distro. Must install docker first, i.e. docker desktop)
    apps             Builds the libs and apps in the submodule
    ami              Create a custom machine image containing the java code, using packer and ansible
    images           Build and push container images using docker compose (need to login to your registry first, set registry to use in the .env file)
    classic          Provision the classic infrastructure with terraform
    eks-base         Provision the EKS infrastructure with terraform
    eks-components   Provision the EKS core components with the terraform helm provider
    eks-apps         Deploy the stack with helm in eks with helm
    clean            Clean up all resources

Note: -auto-approve is used for all terraform commands. Be careful!
```

The clean command may throws errors, which are skipped. This is because it will try to clean up everything, even though not all terraform projects have been initialized yet, or have the infrastructure deployed.

## Terraform

The terraform directory contains two different setups, which can be used depending on the preferences of the development team. These are kubernetes and classic. The recommended approach is to use kubernetes.

Currently all state related files are listed in .gitignore. This is because this repo is meant to showcase some workflows and not to manage actual long living infrastructure.

### Kubernetes

With the kubernetes approach, terraform is used to provision a managed kubernetes cluster (EKS) with nginx as ingress controller. Afterwards helm should be used to deploy the applications into the cluster. If you choose to use kubernetes and want to build the images from scratch, it can be helpful to review the docker and helm section first, to ensure the correct image registry is referenced.

```bash
export NEWSFEED_SERVICE_TOKEN="<my-secret-token>"
make images # the images are already on docker hub. You can technically skip this step
make eks-base
make eks-components
make eks apps
make clean # removes the cluster again!
```

After these steps have been performed, you will see the url of the front-end in the console. Open this url in your browser to view the application. Note that in the first load of the page, you may see an error message. This appears to be an issue with the application code. After refreshing 1 or more times, you should see the newsfeed.

The process is separated into 3 sections. The base command will provision an a bare eks cluster. The components command will deploy some core components into eks. In this case, only an ingress controller. The app command will deploy the actual applications. The reason for the separation is that usually we only need to create the cluster once. And core components are rarely changed. Application deployments on the other hand are frequently, and should be done from a pipeline. The modular approach ensures that a single application deployment does not impact the entire infrastructure.

### Classic

With the classic approach, launch-templates using the AMI created by [packer](https://www.packer.io/) and [ansible](https://www.ansible.com/) are used to spawn ec2 instances and loadbalancer targeting the instances. The backend services are only reachable from within the vpc and are using internal network loadbalancer. The frontend is publicly accessible via the application loadbalancer. The statics are hosted as s3 website. If the launch template version changes, a rolling update on the ec2 instances is triggered.

```bash
export NEWSFEED_SERVICE_TOKEN="<my-secret-token>"
make ami # this may fail at first, due to ansible. After a retry it should work
make classic
```

After these steps have been performed, you will see the url of the front-end in the console. Open this url in your browser to view the application. Note that in the first load of the page, you may see an error message. This appears to be an issue with the application code. After refreshing 1 or more times, you should see the newsfeed. It may also help to wait 1 or 2 minutes before trying to view the webpage.

Building the AMI is a bit shaky due to ansible's nature. If the ami command fails, you can try to run it again until it succeeds.

#### Module

The classic deployment, is making use of a custom module to assist with the configuration of the launch templates and target groups. You can take a look at this module in the *terraform/classic/modules/terraform-aws-rolling-ami-release* directory. The module can be tested with [terratest](https://terratest.gruntwork.io/).

```bash
cd terraform/classic/modules/terraform-aws-rolling-ami-release/tests
go mod download -v
go test -timeout 10m
```

## Docker

The docker folder contains a generic dockerfile to build the clojure apps. Additionally a compose file exists to try out the images locally.

The following command will build the images of they don't exist and start the compose stack.

```bash
export NEWSFEED_SERVICE_TOKEN="<my-secret-token>"
docker-compose up
```

The images can be pushed to a registry using the below command.

```bash
docker-compose push
```

The docker setup, relies on the variables provided by the .env file at the root of this project. You can change the registry and namespace there. Or export them in your shell to overide the values used, since shell takes precedence.

```bash
REGISTRY_FQDN=my-registry.io
REGISTRY_NS=my-namespace
```

Additionally, it may be a good idea to edit the compose file and add specific versions as image tags, depending on your development status. Currently 0.1.0 is used for all images.

## Helm

If you choose to use the docker images for your deployment, you may want to use helm to deploy them into a kubernetes cluster. For this purpose a generic helm chart exists in the helm directory. These could be used from a pipeline.

For example, you could deploy the front-end with.

```bash
helm upgrade front-end helm/charts/generic \
  -f helm/values/front-end.yaml \
  --set env.secret.NEWSFEED_SERVICE_TOKEN="<my-secret-token>" \
  --atomic --namespace newsfeed \
  --create-namespace
  --install
```

The majority of values if provided from a yaml file in the helm/values directory. Some values, like the secret token for example, should be set via the command line, in order to not source control them. Remember to change the referred image in the values file or with the set flag in case you are using a different registry.

## Packer

As an alternative approach to deploy the applications, packer can be leveraged to build machine images. These pre build image(s) can then be deployed as ec2 instances. To perform the deployment, terraform can be used, which has relevant configurations in the terraform/classic directory.

## Room for improvement

### Remote State

It would be good to store terraform's state on a remote backend like s3. The benefit of doing this is that it makes it less error prone when working across a team. Since each time a terraform command is issues its fetching the state from remote. Currently the state is stored locally which yields a high probability that different developers end up with different local state sooner or later.

Currently it is not configured to use remote state so that it works as one shot command, for those who may evaluate this project.

### Domain

A domain can be purchased and the relevant certificate can be placed on either the ALB and via CNAME record on the s3 bucket when using the classical approach. Or the domain could be used by cert-manager when going for EKS.

### Security

Both setups could be further hardened by using private subnets in conjunction with nat gateways. This has not been done as of now, to save development cost.

### Blast Radius

The *blast radius* could be reduced by separating certain configurations. For example, each app could have their own helm chart and/or own ami. This hasn't been done yet for simplicity.

### More Tests

More tests could be created to test the various aspects of this projects. Currently, only the custom module has tests.
