##
## Backend configuration
##
## These variables correspond to the S3 Backend parameters with the same name.
##

variable "name_prefix" {
  type        = string
  description = "Prefix to tack on resources names."
  default     = "anaml"
}

variable "zones" {
  type        = list(string)
  description = "AWS zones for multi-zone resources. They must exist within the configured region."
  default     = ["ap-southeast-2a", "ap-southeast-2b"] # TODO delete
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes Version to use"
  default     = "1.29"
}

variable "iac_environment_tag" {
  type        = string
  description = "Environment identifier to tag on resources"
  default     = "anaml"
}

variable "db_backup_retention_period" {
  type        = number
  description = "Number of days to retain database backups for"
  default     = 7
  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "Database backup retention period must be between 0 and 35 days."
  }
}

variable "kms_key_id" {
  type        = string
  description = "KMS key arn to use for encrypting resources"
  default     = ""
}

##
## NETWORK
##

variable "main_network_block" {
  type        = string
  description = "Base CIDR block to be used in our VPC."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix_extension" {
  type        = number
  description = "CIDR block bits extension to calculate CIDR blocks of each subnetwork."
  default     = 4
}

variable "zone_offset" {
  type        = number
  description = "CIDR block bits extension offset to calculate Public subnets, avoiding collisions with Private subnets."
  default     = 8
}

##
## CLUSTER
##

variable "anaml_instance_types" {
  type        = list(string)
  description = "List of EC2 instance machine types to be used for Anaml in EKS."
  default     = ["t3.large", "t2.large"]
}

variable "spark_instance_types" {
  type        = list(string)
  description = "List of EC2 instance machine types to be used for Spark in EKS."
  default = ["r6i.xlarge", "r6id.xlarge", "r7i.xlarge"]
}

variable "anaml_asg_minimum_size_by_az" {
  type        = number
  description = "Minimum number of EC2 instances to autoscale our EKS cluster on each AZ."
  default     = 1
}

variable "anaml_asg_maximum_size_by_az" {
  type        = number
  description = "Maximum number of EC2 instances to autoscale our EKS cluster on each AZ."
  default     = 3
}

variable "spark_asg_minimum_size_by_az" {
  type        = number
  description = "Minimum number of EC2 instances to autoscale our EKS cluster on each AZ."
  default     = 0
}

variable "spark_asg_maximum_size_by_az" {
  type        = number
  description = "Maximum number of EC2 instances to autoscale our EKS cluster on each AZ."
  default     = 3
}
