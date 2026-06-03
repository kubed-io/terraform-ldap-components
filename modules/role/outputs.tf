output "dn" {
  description = "The full DN of the role (cn=<name>,<base_dn>)."
  value       = ldap_entry.this.dn
}

output "cn" {
  description = "The role's common name."
  value       = local.name
}

output "owner" {
  description = "The owner DN (also the sentinel member when members is empty)."
  value       = var.owner
}

output "members" {
  description = "The resolved authoritative member set written to the role (the owner sentinel when no members were given)."
  value       = toset(local.members)
}
