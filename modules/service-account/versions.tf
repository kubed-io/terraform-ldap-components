terraform {
  required_version = ">= 1.4.4"
  required_providers {
    ldap = {
      source  = "l-with/ldap"
      version = ">= 0.11.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
