terraform {
  required_providers {
    ldap = {
      source  = "l-with/ldap"
      version = ">= 0.11.1"
    }
  }
}

provider "ldap" {
  # host          = "ldap://ldap.example.com:389"
  # bind_user     = "cn=admin,dc=example"
  # bind_password = var.bind_password
}

module "client" {
  source = "../../modules/client"

  name    = "nextcloud"
  base_dn = "ou=clients,dc=example"
  owner   = "uid=nextcloud,ou=services,dc=example"
  url     = "https://nextcloud.example.com"
  roles = [
    { name = "admin", description = "Nextcloud administrators" },
    { name = "media-manager" },
  ]
}

output "dn" {
  value = module.client.dn
}

output "role_dns" {
  value = module.client.role_dns
}
