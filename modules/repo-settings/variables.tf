variable "repository_name" {
  description = "Name of the existing github repository"
  type        = string
}

variable "protect_main" {
  type    = bool
  default = true
}

variable "protect_dev" {
  type    = bool
  default = false
}
