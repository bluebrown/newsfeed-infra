output "lb_dns" {
  value = aws_lb.example.dns_name
}

module "rolling_ami_release" {
  source                       = "../../"
  name_prefix                  = "${module.vpc.name}-nginx-"
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = aws_lb.example.subnets
  target_group_arn             = aws_lb_target_group.example.arn
  instance_ami_id              = "ami-05d34d340fb1d89e5" // amazon linux 2
  instance_type                = "t2.micro"
  instance_desired_count       = 1
  instance_max_count           = 2
  instance_min_count           = 1
  instance_security_groups_ids = [aws_default_security_group.default.id]
  instance_user_data           = file("./startup.sh")
}

// additonal resources
module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "test-vpc"
  cidr           = "10.24.0.0/16"
  azs            = ["eu-central-1a", "eu-central-1b"]
  public_subnets = ["10.24.101.0/24", "10.24.102.0/24"]
}


resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${module.vpc.name}-default-sg"
  }

  // alllow all traffic between the instances and the load balancer
  // via self references
  ingress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
    description = "self ref"
  }

  egress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
    description = "self ref"
  }

  // allow outbound traffic over https
  // to install yum packages
  egress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "https outbound"
  }

}

resource "aws_security_group" "public_load_balancer" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${module.vpc.name}-public-lb-sg"
  }

  // allow http traffic from the public internet
  ingress {
    description      = "http traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_lb" "example" {
  name               = "${module.vpc.name}-example-lb"
  load_balancer_type = "application"

  security_groups = [
    aws_default_security_group.default.id,
    aws_security_group.public_load_balancer.id,
  ]

  subnets = module.vpc.public_subnets

}

resource "aws_lb_target_group" "example" {
  name     = "${module.vpc.name}-example-tg"
  vpc_id   = module.vpc.vpc_id
  port     = 80
  protocol = "HTTP"
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}
