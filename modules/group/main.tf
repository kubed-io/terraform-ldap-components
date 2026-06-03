locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # mail isn't in posixGroup, so pull in extensibleObject only when it's set.
  object_class = concat(["posixGroup"], var.mail != null ? ["extensibleObject"] : [])

  entry = {
    objectClass = local.object_class
    cn          = [local.name]
    gidNumber   = [var.gid_number]
    # set → sorted list so the rendered JSON is order-stable (no spurious diffs)
    memberUid   = sort(tolist(var.members))
    description = compact([var.description])
    mail        = compact([var.mail])
  }
}

resource "ldap_entry" "this" {
  dn = local.dn
  # write only the attributes that have a value
  data_json = jsonencode({
    for k, v in local.entry : k => v if length(v) > 0
  })
}
