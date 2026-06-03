terraform {
  required_providers {
    ldap = {
      source  = "l-with/ldap"
      version = ">= 0.11.1"
    }
  }
}

# Point at your LDAP server. SASL EXTERNAL over ldapi:// works when running
# inside the openldap pod; otherwise set host/bind_user/bind_password.
provider "ldap" {
  # host          = "ldap://openldap.data.svc:389"
  # bind_user     = "cn=admin,dc=example"
  # bind_password = var.bind_password
}

module "service_account" {
  source = "../../modules/service-account"

  name    = "myapp"
  base_dn = "ou=services,dc=example"
  mail    = "myapp@example.com"
  posix = {
    uidNumber = "1050"
    gidNumber = "2001"
  }
}

output "dn" {
  value = module.service_account.dn
}

output "username" {
  value = module.service_account.username
}

output "password" {
  value     = module.service_account.password
  sensitive = true
}
