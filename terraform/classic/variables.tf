variable "ami_id" {
  description = "Generic AMI"
  type        = string
  default     = ""
}

variable "statics_path" {
  description = "Path to static files"
  type        = string
  default     = "../../infra-problem/front-end/public"
}

variable "ssh_key_name" {
  description = "Name of SSH key pair for the instances created by the launch template"
  default     = null

}
