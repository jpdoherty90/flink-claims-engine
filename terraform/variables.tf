variable "sg_package" {
  description = "Stream Governance Package: Advanced or Essentials"
  type        = string
  default     = "ADVANCED"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}