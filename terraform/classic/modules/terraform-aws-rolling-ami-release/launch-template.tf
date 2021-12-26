resource "aws_launch_template" "this" {
  name_prefix                          = "${var.name_prefix}lt-"
  image_id                             = var.instance_ami_id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.instance_key_name
  update_default_version               = true
  vpc_security_group_ids               = var.instance_security_groups_ids
  user_data                            = base64encode(var.instance_user_data)
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}instance"
    }
  }
}
