resource "aws_lb" "quotes" {
  name               = "${module.vpc.name}-quotes-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "quotes" {
  name     = "quotes"
  port     = 8080
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path = "/ping"
  }
}

resource "aws_lb_listener" "quotes" {
  load_balancer_arn = aws_lb.quotes.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quotes.arn
  }
}

module "quotes_release" {
  source = "./modules/terraform-aws-rolling-ami-release"

  name_prefix = "${module.vpc.name}-quotes-"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = aws_lb.quotes.subnets

  target_group_arn = aws_lb_target_group.quotes.arn

  instance_ami_id        = var.ami_id
  instance_type          = "t2.micro"
  instance_key_name      = "dev-box"
  instance_desired_count = 1
  instance_max_count     = 2
  instance_min_count     = 1

  instance_security_groups_ids = [
    aws_default_security_group.internal.id,
    aws_security_group.outbound.id,
  ]

  instance_user_data = <<EOF
#!/bin/bash
{
  echo "APP_JAR=quotes.jar"
  echo "APP_PORT=8080"
} >> /usr/share/java/.env
systemctl enable java-app
systemctl start java-app
EOF
}
