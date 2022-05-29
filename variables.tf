# Provider variables
variable "region" {}

variable "x" {
  default="4"
}

variable "vpc_id" {
  default="vpc-00e35cec217b5d441"
}

variable "public_subnet_id" {
  default="subnet-0385835828df121eb"
}

variable "private_subnet_id_1" {
  default="subnet-06f6ab1705a51042d"
}

variable "private_subnet_id_2" {
  default="subnet-09dd42e5c589ea1d2"
}
