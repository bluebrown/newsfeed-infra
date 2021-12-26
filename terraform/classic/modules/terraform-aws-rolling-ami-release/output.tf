output "placement_group_id" {
  value = aws_placement_group.this.id
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "autoscaling_group_id" {
  value = aws_autoscaling_group.this.id
}

output "ami_id" {
  value = aws_launch_template.this.image_id
}
