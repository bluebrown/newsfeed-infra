resource "aws_autoscaling_group" "this" {
  name = "${var.name_prefix}asg"

  vpc_zone_identifier = var.subnet_ids

  desired_capacity = var.instance_desired_count
  max_size         = var.instance_max_count
  min_size         = var.instance_min_count
  placement_group  = aws_placement_group.this.id

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "ami"
    value               = aws_launch_template.this.image_id
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  alb_target_group_arn   = var.target_group_arn
}
