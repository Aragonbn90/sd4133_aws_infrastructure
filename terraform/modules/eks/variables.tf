variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_types" {
  type    = list(string)
  default = ["t2.small"]
}

variable "capacity_type" {
  type = string
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 1
}

variable "desired_size" {
  type    = number
  default = 1
}

variable "private_subnets" {
  type = list(string)
}

variable "intra_subnets" {
  type = list(string)
}

variable "tags" {
  type = object({
  })
}

# variable "labels" {
#   type = object({
#   })
# }

# variable "taints" {
#   type = object({
#   })
# }

variable "key_arn" {
  type = string
}

variable "create_ebs_csi_driver" {
  type = bool
  default = false
}

