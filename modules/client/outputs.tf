output "dn" {
  description = "The full DN of the client root (cn=<name>,<base_dn>)."
  value       = ldap_entry.root.dn
}

output "cn" {
  description = "The client's common name."
  value       = local.name
}

output "owner" {
  description = "The owning service account DN — written as roleOccupant on the root and seeded as the initial member of each role child."
  value       = var.owner
}

output "role_dns" {
  description = "Map of role name → full DN of its client-role child entry."
  value       = { for name, r in ldap_entry.role : name => r.dn }
}

output "default_role" {
  description = "The client-role designated default (flagged default:true, else the first declared role). Members in this role have no parent role downstream; members in any other role are nested under it."
  value       = local.default_role
}

output "members" {
  description = <<EOF
The FULL merged membership of every role child as a flat list of { dn, role } — the
union of the owner seed, externally-added members, and the serviceAccountSelector-resolved
members (i.e. local.role_members flattened, role = the client-role each member belongs to).
This is what a consumer (e.g. the postgresql Server) reads to build its own derived objects.
Distinct from selectedMembers (selector-only, pre-merge).
EOF
  value = flatten([
    for name, dns in local.role_members : [
      for dn in dns : { dn = dn, role = name }
    ]
  ])
}
