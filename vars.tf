variable "project_name" {
  type    = string
  default = "swarm"
}

variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "availability_zones" {
  type    = list(string)
  default = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
}

variable "base_cidr_block" {
  type    = string
  default = "10.254.254.0/24"
}

variable "forwarded_ports" {
  type    = list(string)
  default = [443, 80, 22]
}

variable "key_name" {
  type = string
  default = "swarm-key-pair"
}
