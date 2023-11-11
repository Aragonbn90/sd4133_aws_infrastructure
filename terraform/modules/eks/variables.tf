variable "name" {
  type = string
  nullable = false
}

variable "eks_type" {
  type = string
  description = "One of values: eks_managed, self_managed, fargate"
  default = "eks_managed"
  # validation {
  #   condition = false
  #   error_message = "Wrong eks type"
  # }
  nullable = false
}

variable "vpc_id" {
  type = string
  nullable = false
}

variable "instance_types" {
  type    = list(string)
  default = ["t2.small"]
}

variable "capacity_type" {
  type = string
  default  = "ON_DEMAND"
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

variable "ami_type" {
  type = string
  default = "AL2_x86_64"
}

variable "key_arn" {
  type = string
}

variable "create_ebs_csi_driver" {
  type = bool
  default = false
}

