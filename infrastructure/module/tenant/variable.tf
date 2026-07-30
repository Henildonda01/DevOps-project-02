variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 24.04"
  type        = string
  default     = "ami-0e86e20dae9224db8"
}

variable "key_name" {
  description = "EC2 key pair name for SSH"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed for HTTP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in. Leave null to use the default VPC's default subnet."
  type        = string
  default     = null
}
