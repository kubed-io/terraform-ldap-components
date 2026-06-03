locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # labeledURI isn't in groupOfNames, so pull in labeledURIObject only when url is set.
  root_object_class = concat(["groupOfNames"], var.url != null ? ["labeledURIObject"] : [])

  # keyed by role name for stable for_each addressing
  roles = { for r in var.roles : r.name => r }

  # --- preserve externally-managed members (see team module for the rationale) ---
  # Read CURRENT members of the root and each role child from the live server. The
  # plural data source returns an empty list when an entry doesn't exist yet (first
  # create), so members = owner UNION existing — TF never wipes external additions.
  root_existing_members = try(
    jsondecode(data.ldap_entries.root.entries[0].data_json).member,
    [],
  )
  root_members = distinct(concat([var.owner], local.root_existing_members))

  role_members = {
    for name, r in local.roles : name => distinct(concat(
      [var.owner],
      try(jsondecode(data.ldap_entries.role[name].entries[0].data_json).member, []),
    ))
  }

  # NOTE: cn is the RDN on the root and every role child (dn = cn=<name>,...); omitted
  # from data (server adds it implicitly; writing it makes a modify re-add it → LDAP
  # error 20 "Attribute Or Value Exists").
  root_entry = {
    objectClass      = local.root_object_class
    owner            = [var.owner]
    member           = local.root_members
    labeledURI       = compact([var.url])
    description      = compact([var.description])
    seeAlso          = compact([var.see_also])
    businessCategory = compact([var.category])
    o                = compact([var.org])
    ou               = compact([var.org_unit])
  }
}

# Live members of the client root (empty before it exists), searched under base_dn.
data "ldap_entries" "root" {
  ou     = var.base_dn
  filter = "cn=${local.name}"
}

# Live members of each role child, searched under the client root DN.
data "ldap_entries" "role" {
  for_each = local.roles
  ou       = local.dn
  filter   = "cn=${each.value.name}"
}

resource "ldap_entry" "root" {
  dn = local.dn
  data_json = jsonencode({
    for k, v in local.root_entry : k => v if length(v) > 0
  })
  # No ignore_attributes: desired `member` always re-includes the live set (merge),
  # so external additions survive.
}

resource "ldap_entry" "role" {
  for_each = local.roles

  dn = "cn=${each.value.name},${local.dn}"
  data_json = jsonencode(merge(
    {
      objectClass = ["groupOfNames"]
      owner       = [var.owner]
      member      = local.role_members[each.key]
    },
    each.value.description != null ? { description = [each.value.description] } : {},
  ))
}
