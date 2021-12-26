resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  write_kubeconfig = true

  cluster_name    = local.cluster_name
  cluster_version = "1.21"

  subnets = module.vpc.public_subnets
  vpc_id  = module.vpc.vpc_id

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                 = "on-demand-1"
      instance_type        = "t2.micro"
      asg_min_size         = 2
      asg_max_size         = 5
      asg_desired_capacity = 2
      kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal"
      suspended_processes  = ["AZRebalance"]
    },
    {
      name                 = "spot-1"
      instance_type        = "t2.micro"
      spot_price           = "0.035"
      asg_min_size         = 2
      asg_max_size         = 5
      asg_desired_capacity = 2
      kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=spot"
      suspended_processes  = ["AZRebalance"]
    },
  ]
}
