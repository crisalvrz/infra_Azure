variable "location" {
  type    = string
  default = "westeurope"
}

variable "rg_name" {
  type    = string
  default = "rg-proyecto-hubspoke"
}

variable "hub_cidr" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "spoke_cidr" {
  type    = list(string)
  default = ["192.168.0.0/16"]
}
