locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # labeledURI isn't in groupOfNames, so pull in labeledURIObject only when url is set.
  root_object_class = concat(["groupOfNames"], var.url != null ? ["labeledURIObject"] : [])

  # NOTE: cn is the RDN on the root and every role child (dn = cn=<name>,...); omitted
  # from data (server adds it implicitly; writing it makes a modify re-add it → LDAP
  # error 20 "Attribute Or Value Exists").
  root_entry = {
    objectClass      = local.root_object_class
    owner            = [var.owner]
    # seed owner as the initial member to satisfy the >=1-member MUST; membership is
    # ignored below so an external tool owns it.
    member           = [var.owner]
    labeledURI       = compact([var.url])
    description      = compact([var.description])
    seeAlso          = compact([var.see_also])
    businessCategory = compact([var.category])
    o                = compact([var.org])
    ou               = compact([var.org_unit])
  }

  # keyed by role name for stable for_each addressing
  roles = { for r in var.roles : r.name => r }
}

resource "ldap_entry" "root" {
  dn = local.dn
  data_json = jsonencode({
    for k, v in local.root_entry : k => v if length(v) > 0
  })
  ignore_attributes = ["member"]
}

resource "ldap_entry" "role" {
  for_each = local.roles

  dn = "cn=${each.value.name},${local.dn}"
  data_json = jsonencode(merge(
    {
      objectClass = ["groupOfNames"]
      owner       = [var.owner]
      member      = [var.owner] # seed for the >=1-member MUST; ignored below
    },
    each.value.description != null ? { description = [each.value.description] } : {},
  ))
  ignore_attributes = ["member"]
}
