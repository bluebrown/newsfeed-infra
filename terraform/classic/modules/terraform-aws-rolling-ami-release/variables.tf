
variable "name_prefix" {
  default     = ""
  description = "Name prefix for the resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  default     = []
  description = "Subnet IDs create the resources in"
  type        = list(any)
}

variable "target_group_arn" {
  default     = ""
  description = "Target group arn"
  type        = string
}

variable "instance_ami_id" {
  default     = ""
  description = "AMI ID to use for the instances"
  type        = string
}

variable "instance_security_groups_ids" {
  default     = []
  description = "Security group IDs to use for the instances"
  type        = list(any)

}

variable "instance_type" {
  default     = "t2.micro"
  description = "Instance type to use for the instances"
  type        = string
}

variable "instance_key_name" {
  default     = null
  description = "Key name to use for the instances"
}

variable "instance_user_data" {
  default     = ""
  description = "User data to use for the instances"
  type        = string
}

variable "instance_desired_count" {
  default     = 1
  description = "Number of instances to create"
  type        = number
}

variable "instance_max_count" {
  default     = 2
  description = "Maximum number of instances to create"
  type        = number
}

variable "instance_min_count" {
  default     = 1
  description = "Minimum number of instances to create"
  type        = number
}
