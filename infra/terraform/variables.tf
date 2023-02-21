variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources will be deployed"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "unique_username" {
  type        = string
  description = "This value will explain who is the author of specific resources and will be reflected in every deployed tool"
}

variable "aks_aad_auth" {
  type        = bool
  description = "Configure Azure Active Directory authentication for Kubernetes cluster"
  default     = false
}

variable "aks_aad_admin_user_object_id" {
  type        = string
  description = "Object ID of the AAD user to be added as an admin to the AKS cluster"
  default     = ""
}
