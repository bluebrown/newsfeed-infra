resource "aws_lb" "front_end" {
  name               = "${module.vpc.name}-frontend-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_default_security_group.internal.id,
    aws_security_group.public_load_balancer.id,
  ]

  subnets = module.vpc.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    enabled = true
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "${module.vpc.name}-frontend-tg"
  vpc_id   = module.vpc.vpc_id
  port     = 8080
  protocol = "HTTP"
  health_check {}
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

module "frontend_release" {
  source = "./modules/terraform-aws-rolling-ami-release"

  name_prefix = "${module.vpc.name}-frontend-"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = aws_lb.front_end.subnets

  target_group_arn = aws_lb_target_group.front_end.arn

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
  echo "APP_JAR=front-end.jar"
  echo "APP_PORT=8080"
  echo "STATIC_URL=http://${aws_s3_bucket.statics.bucket_domain_name}"
  echo "QUOTE_SERVICE_URL=http://${aws_lb.quotes.dns_name}"
  echo "NEWSFEED_SERVICE_URL=http://${aws_lb.newsfeed.dns_name}"
} >> /usr/share/java/.env
systemctl enable java-app
systemctl start java-app
EOF
}
