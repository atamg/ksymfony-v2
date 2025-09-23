# Declares input variables for project, AWS, networking, SSH, logging, and instance settings.

variable "project_name" { 
  type = string
  default = "ksymfony-v2" 
  }
variable "aws_region"   { 
  type = string
  default = "eu-north-1" 
  }

variable "vpc_id"    { 
  type = string
  description = "Existing VPC ID" 
  }
variable "subnet_id" { 
  type = string
  description = "Existing public subnet ID" 
  }

variable "enable_ssh"       { 
  type = bool
  default = false 
  }
variable "key_pair_name"    { 
  type = string
  description = "Existing EC2 key pair name" 
  }

variable "open_http_80"   { 
  type = bool
  default = true 
  }

variable "open_https_443" { 
  type = bool
  default = false 
  }

variable "github_owner" { 
  type = string 
  default = "atamg" 
  }
variable "github_repo"  { 
  type = string 
  default = "ksymfony-v2" 
  }
variable "allowed_refs" {
  type    = list(string)
  default = ["refs/heads/main", "refs/tags/v*"]
}

variable "cw_logs_retention_days" { 
  type = number
  default = 14 
  }

variable "instance_type" { 
  type = string
  default = "t3.micro" 
  }

locals {
  oidc_sub_values = [
    for r in var.allowed_refs :
    "repo:${var.github_owner}/${var.github_repo}:ref:${r}"
  ]
}

variable "extra_ssh_public_keys" {
  type        = list(string)
  description = "Extra SSH public keys appended to /home/ec2-user/.ssh/authorized_keys"
  default     = []
}

variable "user_allowed_ip_list" {
  type        = list(string)
  description = "Static SSH allow-list (IPv4 CIDRs)."
  default     = []
}
