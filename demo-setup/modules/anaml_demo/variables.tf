variable "source_id" {
  type        = number
  description = "The ID of the Anaml source to run retrieve table datas from."
}

variable "cluster_id" {
  type        = number
  description = "The ID of the Anaml cluster to run feature stores and previews on."
}

variable "destination_id" {
  type        = number
  description = "The ID of the Anaml destination to write stores to."
}

variable "source_type" {
  type        = string
  description = "The type of the source: local|gcs"
}

variable "destination_type" {
  type        = string
  description = "The type of the destination: local|gcs"
}

output "customer_entity_id" {
  value = anaml_entity.customer.id
}

output "plan_entity_id" {
  value = anaml_entity.phone_plan.id
}
