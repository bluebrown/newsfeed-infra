module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "eks-vpc-${local.cluster_name}"
  cidr           = "10.3.0.0/16"
  azs            = ["eu-central-1a", "eu-central-1b"]
  public_subnets = ["10.3.1.0/24", "10.3.2.0/24"]

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

}


