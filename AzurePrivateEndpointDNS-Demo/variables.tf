# Azure Subscription should ne defined as environmental variable to import
variable "AZURE_SUBSCRIPTION_ID" {
  type = string
}

# Azure Resource Group to use
variable "lab-rg" {
  description = "Resource Group for this lab"
  type        = string
  default     = "PrivateEndpointDNSDemoRG"
}

# Azure region
variable "lab-location" {
  description = "Resource location"
  type        = string
  default     = "PolandCentral"
}

# Tags for resources
variable "tags" {
  description = "Set of tags for resources"
  type        = map(any)
  default = {
    environment = "PrivateEndpointDNS-demo"
    deployment  = "terraform"
  }
}

variable "username" { default = "azureuser" }
variable "password" { default = "Cisco123!!Admin" }