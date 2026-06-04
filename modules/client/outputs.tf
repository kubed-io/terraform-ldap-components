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
