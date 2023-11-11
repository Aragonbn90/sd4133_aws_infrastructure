variable "env" {
  type        = string
  default     = "dev"
  description = "The environment"
  nullable    = false
}

variable "instance_types" {
  type     = list(string)
  default  = ["t2.micro"]
  nullable = false
}

variable "capacity_type" {
  type     = string
  default  = "ON_DEMAND"
  nullable = false
}

variable "min_size" {
  type = number
  default = 1
  nullable = false
}

variable "desired_size" {
  type = number
  default = 1
  nullable = false
}

variable "max_size" {
  type = number
  default = 1
  nullable = false
}