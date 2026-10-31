variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "jenkins_sg_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
