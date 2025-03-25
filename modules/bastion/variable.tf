# shared/modules/bastion/variables.tf

variable "stage" {
  description = "Environment stage (e.g., dev, stage, prod)"
  type        = string
}

variable "servicename" {
  description = "Service name used for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the bastion will be deployed"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC for internal communication"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where the bastion will be deployed"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the bastion instance (Amazon Linux 2 recommended)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name for the bastion instance"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}
#
#variable "kms_key_id" {
#  description = "KMS key ID for EBS encryption"
#  type        = string
#}

variable "instance_profile" {
  description = "Instance profile name for the bastion"
  type        = string
  default     = ""
}

variable "ssh_allow_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to the bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access the admin interface"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion"
  type        = string
  default = ""
}