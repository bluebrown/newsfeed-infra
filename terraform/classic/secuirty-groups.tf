resource "aws_default_security_group" "internal" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${module.vpc.name}-internal-sg"
  }

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

  // this is required since nlb cant have security groups attached to it
  // makes the self ref above useless, but keeping it here for completeness
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "vpc cidr"
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "vpc cidr"
  }

}

resource "aws_security_group" "public_load_balancer" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${module.vpc.name}-public-lb-sg"
  }

  ingress {
    description      = "http traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "https traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_security_group" "outbound" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${module.vpc.name}-outbound-sg"
  }

  egress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "http traffic"
  }

  egress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "https traffic"
  }

}
