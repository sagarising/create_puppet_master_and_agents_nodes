variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

variable "agents" {
  type = number
  default = 2
  description = "number of puppet agents to be created"
}

variable "image_id" {
  type = string
  description = "OS for the nodes. Better keep it to bionic"
}
