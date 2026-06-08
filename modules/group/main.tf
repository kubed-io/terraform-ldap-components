locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # mail isn't in posixGroup, so pull in extensibleObject only when it's set.
  object_class = concat(["posixGroup"], var.mail != null ? ["extensibleObject"] : [])

  # --- membership: UNION of var.members (curated + selector, already merged by the
  # composition) with the CURRENT live memberUid read back from the server. Same merge
  # the team module does for `member` — the plural data source safely returns [] when
  # the entry doesn't exist yet (first create). Because the desired set always re-includes
  # the live uids, TF never computes them as "removed", so ad-hoc grants survive.
  existing_members = try(
    jsondecode(data.ldap_entries.existing.entries[0].data_json).memberUid,
    [],
  )
  members = distinct(concat(tolist(var.members), local.existing_members))

  # NOTE: cn is the RDN (dn = cn=<name>,...). The LDAP server adds it implicitly from
  # the DN, and the provider ignores it on read — so we must NOT write cn into data_json
  # or a modify re-adds it and the server rejects with "Attribute Or Value Exists" (20).
  entry = {
    objectClass = local.object_class
    gidNumber   = [var.gid_number]
    # sorted so the rendered JSON is order-stable (no spurious diffs)
    memberUid   = sort(local.members)
    description = compact([var.description])
    mail        = compact([var.mail])
  }
}

# Live memberUid of this group (empty before it exists). Searched under the parent DN —
# same shape as the team module's lookback, so the write below is a union, not a replace.
data "ldap_entries" "existing" {
  ou     = var.base_dn
  filter = "cn=${local.name}"
}

resource "ldap_entry" "this" {
  dn = local.dn
  # write only the attributes that have a value
  data_json = jsonencode({
    for k, v in local.entry : k => v if length(v) > 0
  })
  # No ignore_attributes: desired memberUid always re-includes the live set (union),
  # so external additions survive.
}
