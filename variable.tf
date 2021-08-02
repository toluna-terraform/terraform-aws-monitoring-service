variable "env_name" {
    type = string
}

variable "short_env_name" {
    type = string
}

variable "vpc_id" {
  type = string
}

variable "service_subnets" {
    type = list(string)
}

variable "db_subnets" {
    type = list(string)
}

variable "hosted_zone" {
  type = string
  description = "Route53 Hosted Zone Domain Name"
}

variable "tags" {
}

variable "enable_deletion_protection" {
  type = bool 
  default = false
}

variable "backup_retention_period" {
  default = 3
  
}