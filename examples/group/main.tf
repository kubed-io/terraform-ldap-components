terraform {
  required_providers {
    ldap = {
      source  = "l-with/ldap"
      version = ">= 0.11.1"
    }
  }
}

provider "ldap" {
  # host          = "ldap://openldap.data.svc:389"
  # bind_user     = "cn=admin,dc=example"
  # bind_password = var.bind_password
}

module "group" {
  source = "../../modules/group"

  name       = "media"
  base_dn    = "ou=groups,dc=example"
  gid_number = "2020"
  members    = ["alice", "myapp"]
}

output "dn" {
  value = module.group.dn
}

output "members" {
  value = module.group.members
}
