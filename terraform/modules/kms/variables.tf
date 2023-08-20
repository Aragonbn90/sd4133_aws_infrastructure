variable "name" {
  type = string
}

variable "tags" {
  type = object({})
}

variable "aws_caller_identity_arn" {
  type = string
}
