# A trivial, provider-less Terraform configuration.
#
# It declares no resources and no providers, so `terraform init`, `plan`,
# `validate` and `apply` all run fully offline - ideal as a smoke test and
# as a first thing to try with the image.

terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "Name to greet"
  type        = string
  default     = "world"
}

output "greeting" {
  value = "Hello, ${var.name}!"
}
