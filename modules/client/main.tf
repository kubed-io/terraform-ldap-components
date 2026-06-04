locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # keyed by role name for stable for_each addressing
  roles = { for r in var.roles : r.name => r }

  # --- ROOT object class ---------------------------------------------------
  # The client root is a pure CONTAINER for the role children — NOT a membership
  # group. Access to the app = "member of any client-role child" (see the IAM plan
  # §6.0), so the root needs no `member` and is modeled as an organizationalRole
  # (STRUCTURAL, MUST cn only — no required member). It carries the SA back-link as
  # `roleOccupant` (organizationalRole's native "who occupies this role" DN attr).
  #
  # organizationalRole MAY: description, seeAlso, ou, roleOccupant (native). It does
  # NOT define `businessCategory` (category) or `o` (org) or `labeledURI` (url), so we
  # pull in auxiliary classes only when those are set — same pattern as the other kinds.
  root_aux = concat(
    var.url != null ? ["labeledURIObject"] : [],
    (var.category != null || var.org != null) ? ["extensibleObject"] : [],
  )
  root_object_class = concat(["organizationalRole"], local.root_aux)

  # NOTE: cn is the RDN on the root and every role child (dn = cn=<name>,...); omitted
  # from data (server adds it implicitly; writing it makes a modify re-add it → LDAP
  # error 20 "Attribute Or Value Exists").
  root_entry = {
    objectClass      = local.root_object_class
    roleOccupant     = [var.owner]   # the service account that runs/occupies this client
    labeledURI       = compact([var.url])
    description      = compact([var.description])
    seeAlso          = compact([var.see_also])
    businessCategory = compact([var.category])
    o                = compact([var.org])
    ou               = compact([var.org_unit])
    # no `member` on the root — membership lives on the role children below
  }

  # --- role children: preserve externally-managed members ------------------
  # Each role child IS a groupOfNames (MUST >=1 member). Read its CURRENT members
  # from the live server (empty before it exists) and write owner UNION existing, so
  # the owner seed satisfies the MUST on first create and external grants survive
  # every reconcile (same merge as the team module).
  role_members = {
    for name, r in local.roles : name => distinct(concat(
      [var.owner],
      try(jsondecode(data.ldap_entries.role[name].entries[0].data_json).member, []),
    ))
  }
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
  # No `member` and nothing externally managed here — the root is pure structure.
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
  # No ignore_attributes: desired `member` always re-includes the live set (merge),
  # so external additions survive.
}
