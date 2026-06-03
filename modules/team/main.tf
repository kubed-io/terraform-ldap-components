locals {
  name = coalesce(var.name, terraform.workspace)
  dn   = "cn=${local.name},${var.base_dn}"

  # groupOfNames carries all of these as MAY natively — no aux objectClass.
  entry = {
    objectClass      = ["groupOfNames"]
    cn               = [local.name]
    owner            = [var.owner]
    # seed owner as the initial member so the entry satisfies the >=1-member MUST;
    # `member` is ignored below so an external tool owns real membership.
    member           = [var.owner]
    description      = compact([var.description])
    seeAlso          = compact([var.see_also])
    businessCategory = compact([var.category])
    o                = compact([var.org])
    ou               = compact([var.org_unit])
  }
}

resource "ldap_entry" "this" {
  dn = local.dn
  data_json = jsonencode({
    for k, v in local.entry : k => v if length(v) > 0
  })

  # Membership is externally managed (e.g. an onboarding workflow). TF seeds one
  # member (owner) for schema validity, then never touches `member` again.
  ignore_attributes = ["member"]
}
