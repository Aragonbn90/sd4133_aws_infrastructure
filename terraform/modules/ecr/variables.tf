variable "repository_name" {
  type = string
}
variable "keep_last_images" {
  type = number
  default = 10
}

variable "arn" {
  type = string
}

variable "tags" {
  type = object({})
}

variable "create_repository_policy" {
  type = bool
  default = false
}

variable "repository_policy" {
  type = string
  default = null
}