locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # --- preserve externally-managed members ---
  # Read the team's CURRENT members from the live server. The plural data source
  # safely returns an empty list when the entry doesn't exist yet (e.g. first create),
  # unlike the singular ldap_entry data source which hard-fails on a missing object.
  existing_members = try(
    jsondecode(data.ldap_entries.existing.entries[0].data_json).member,
    [],
  )
  # Desired membership = the owner seed UNION whatever is already there. Because the
  # desired set always includes the live members, Terraform never computes them as
  # "removed", so external additions (and removals) survive each reconcile. The owner
  # seed guarantees groupOfNames' >=1-member MUST on first create (when existing is []).
  members = distinct(concat([var.owner], local.existing_members))

  # groupOfNames carries all of these as MAY natively — no aux objectClass.
  # NOTE: cn is the RDN (dn = cn=<name>,...); the server adds it implicitly and the
  # provider ignores it on read. Writing it here makes a modify re-add it → LDAP error
  # 20 "Attribute Or Value Exists". So cn is intentionally omitted from the data.
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

# Live members of this team (empty before it exists). Searched under the parent DN.
data "ldap_entries" "existing" {
  ou     = var.base_dn
  filter = "cn=${local.name}"
}

resource "ldap_entry" "this" {
  dn = local.dn
  data_json = jsonencode({
    for k, v in local.entry : k => v if length(v) > 0
  })
  # No ignore_attributes: TF writes `member`, but its desired set always re-includes
  # the live members (via the data source above), so externally-added members are
  # preserved rather than wiped.
}
