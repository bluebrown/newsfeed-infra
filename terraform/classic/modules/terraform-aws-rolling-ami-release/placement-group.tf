resource "aws_placement_group" "this" {
  name     = "${var.name_prefix}pg"
  strategy = "partition"
}
