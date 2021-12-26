module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "classic-vpc"
  cidr           = "10.0.0.0/16"
  azs            = ["eu-central-1a", "eu-central-1b"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
}


