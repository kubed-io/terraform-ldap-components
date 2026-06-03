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

module "role" {
  source = "../../modules/role"

  name    = "admins"
  base_dn = "ou=roles,dc=example"
  owner   = "uid=alice,ou=users,dc=example"
  members = [
    "uid=alice,ou=users,dc=example",
    "uid=bob,ou=users,dc=example",
  ]
  description = "Full admin across apps that honor it."
}

output "dn" {
  value = module.role.dn
}

output "members" {
  value = module.role.members
}
