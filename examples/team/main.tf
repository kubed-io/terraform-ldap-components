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

module "team" {
  source = "../../modules/team"

  name        = "staff"
  base_dn     = "ou=teams,dc=example"
  owner       = "uid=alice,ou=users,dc=example"
  description = "Internal staff"
}

output "dn" {
  value = module.team.dn
}
