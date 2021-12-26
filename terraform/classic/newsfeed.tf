resource "aws_lb" "newsfeed" {
  name               = "${module.vpc.name}-newsfeed-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "newsfeed" {
  name     = "newsfeed"
  port     = 8080
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path = "/ping"
  }
}

resource "aws_lb_listener" "newsfeed" {
  load_balancer_arn = aws_lb.newsfeed.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.newsfeed.arn
  }
}


module "newsfeed_release" {
  source = "./modules/terraform-aws-rolling-ami-release"

  name_prefix = "${module.vpc.name}-newsfeed-"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = aws_lb.newsfeed.subnets

  target_group_arn = aws_lb_target_group.newsfeed.arn

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
  echo "APP_JAR=newsfeed.jar"
  echo "APP_PORT=8080"
} >> /usr/share/java/.env
systemctl enable java-app
systemctl start java-app
EOF
}
