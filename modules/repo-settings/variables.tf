variable "repository_name" {
  description = "Name of the existing github repository"
  type        = string
}

variable "labels" {
  description = "Github Labels"
  type = map(object({
    color       = optional(string, "0075ca")
    description = optional(string, "")
  }))
  default = {}
}
