variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project" {
  type    = string
  default = "cheap-fullstack"
}

variable "my_ip_cidr" {
  type = string
}

variable "az" {
  type    = string
  default = "eu-central-1a"
}

variable "az_b" {
  type        = string
  description = "Second availability zone (e.g. eu-central-1b)"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "public_subnet_b_cidr" {
  type        = string
  description = "CIDR for second public subnet (e.g. 10.20.3.0/24)"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.20.2.0/24"
}

variable "instance_type_bastion" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_app" {
  type    = string
  default = "t3.small"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Absolute path to your public SSH key, e.g. /Users/pavlo/.ssh/id_ed25519.pub"
}

