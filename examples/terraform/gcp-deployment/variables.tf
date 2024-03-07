variable "initial_admin_email" {
  type        = string
  description = "The initial default admin email"
}

variable "initial_admin_password" {
  type        = string
  description = "The initial default admin password"
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the GKE cluster in"
}

variable "region" {
  type        = string
  description = "The region to host the cluster in"
}


variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in"
}
