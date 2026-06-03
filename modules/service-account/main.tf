locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "uid=${local.name},${var.base_dn}"
  sn   = coalesce(var.sn, local.name)

  home_directory = coalesce(var.posix.homeDirectory, "/home/${local.name}")

  generate_password = var.password == null
  user_password     = local.generate_password ? random_password.this[0].result : var.password

  # inetOrgPerson + posixAccount carry every attribute below as MAY/MUST, so no
  # auxiliary objectClass is needed (description and mail are both MAY on
  # inetOrgPerson). compact() drops the optional keys that are null.
  entry = {
    objectClass   = ["inetOrgPerson", "posixAccount"]
    cn            = [local.name]
    sn            = [local.sn]
    uidNumber     = [var.posix.uidNumber]
    gidNumber     = [var.posix.gidNumber]
    homeDirectory = [local.home_directory]
    loginShell    = [var.posix.loginShell]
    userPassword  = [local.user_password]
    description   = compact([var.description])
    mail          = compact([var.mail])
  }
}

resource "random_password" "this" {
  count            = local.generate_password ? 1 : 0
  length           = var.password_policy.length
  special          = var.password_policy.special
  numeric          = var.password_policy.numeric
  upper            = var.password_policy.upper
  lower            = var.password_policy.lower
  min_special      = var.password_policy.minSpecial
  min_numeric      = var.password_policy.minNumeric
  min_upper        = var.password_policy.minUpper
  min_lower        = var.password_policy.minLower
  override_special = var.password_policy.overrideSpecial
}

resource "ldap_entry" "this" {
  dn = local.dn
  # write only the attributes that have a value
  data_json = jsonencode({
    for k, v in local.entry : k => v if length(v) > 0
  })
}
