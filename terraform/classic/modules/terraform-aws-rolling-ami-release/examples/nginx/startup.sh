#!/bin/bash

yum update -y
yum install -y amazon-linux-extras
amazon-linux-extras enable nginx1
yum clean metadata
yum install -y nginx
systemctl enable nginx
systemctl start nginx
