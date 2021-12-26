packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


variable "dryrun" {
  default = false
}

variable "newsfeed_token" {
  default = ""
}

source "amazon-ebs" "ubuntu" {
  skip_create_ami = var.dryrun

  instance_type = "t2.micro"
  region        = "eu-central-1"
  source_ami    = "ami-0d527b8c289b4af7f" # ubuntu 20.04 free tier
  ssh_username  = "ubuntu"

  tags = {
    OS_Version    = "Ubuntu"
    Release       = "Latest"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
    Example       = "true"
  }

}

build {
  source "amazon-ebs.ubuntu" {
    ami_name = "java-runner-{{timestamp}}"
  }

  provisioner "ansible" {
    playbook_file = "playbook.yaml"
    extra_arguments = [
      "--extra-vars", "newsfeed_token='${var.newsfeed_token}'",
    ]
  }

  post-processor "manifest" {}

}
