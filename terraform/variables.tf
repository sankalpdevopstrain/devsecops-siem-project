# ============================================================
# DevSecOps Platform — Variables
# ============================================================

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for eu-west-2"
  type        = string
  default     = "ami-0abb2deaf550b3d9a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "devsecops-key"
}

variable "siem_url" {
  description = "Your local SIEM dashboard URL — ngrok public URL"
  type        = string
  default     = "https://previous-stinky-maturity.ngrok-free.dev"
}
