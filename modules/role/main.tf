locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # Authoritative member list, sorted for order-stable JSON. groupOfNames needs
  # >=1 member, so fall back to the owner sentinel when no real members are set.
  members = length(var.members) > 0 ? sort(tolist(var.members)) : [var.owner]

  # groupOfNames carries all of these as MAY natively — no aux objectClass.
  # NOTE: cn is the RDN (dn = cn=<name>,...); omitted from data (server adds it
  # implicitly; writing it makes a modify re-add it → LDAP error 20).
  entry = {
    objectClass      = ["groupOfNames"]
    owner            = [var.owner]
    member           = local.members
    description      = compact([var.description])
    seeAlso          = compact([var.see_also])
    businessCategory = compact([var.category])
    o                = compact([var.org])
    ou               = compact([var.org_unit])
  }
}

resource "ldap_entry" "this" {
  dn = local.dn
  # TF is the sole writer of `member` (authoritative) — no ignore_attributes.
  data_json = jsonencode({
    for k, v in local.entry : k => v if length(v) > 0
  })
}
