variable "anaml_api_url" {
  type        = string
  description = "The externally accessible URL for the Anaml Server."
  default     = "http://localhost:8081/api"
}

variable "anaml_api_apikey" {
  type        = string
  description = "The API Key to use to authenticate Anaml API requests."
}

variable "anaml_api_secret" {
  type        = string
  description = "The Secret to use to authenticate Anaml API requests."
}

variable "anaml_branch" {
  type        = string
  description = "The Anaml branch to create resources under."
  default     = "official"
}